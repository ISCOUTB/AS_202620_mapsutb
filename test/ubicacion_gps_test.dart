import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/services/ubicacion_service.dart';
import 'package:mapsutb/services/ubicacion_service_gps.dart';

/// GPS real sin GPS: la fuente es un doble y el reloj es falso. Cada prueba
/// lleva el ID de la fila de arc42 §11 que cubre (MF-04 a MF-06).

final _t0 = DateTime(2026, 10, 13, 9);

/// A ~11 m por cada 0,0001° de latitud.
Ubicacion _lectura({double dLat = 0, double precision = 5, Duration edad = Duration.zero, DateTime? ahora}) =>
    Ubicacion(
      lat: 10.3700 + dLat,
      lng: -75.4655,
      timestamp: (ahora ?? _t0).subtract(edad),
      precisionM: precision,
    );

class _FuenteFalsa implements FuenteGps {
  _FuenteFalsa({this.permiso, this.permisoPendiente});
  final MotivoSinUbicacion? permiso;

  /// Si se da, el permiso no se resuelve hasta que la prueba lo complete
  /// (el aviso del navegador sigue abierto).
  final Completer<MotivoSinUbicacion?>? permisoPendiente;

  /// Broadcast: el servicio se suscribe de nuevo cada vez que vuelve a tener oyentes.
  final lecturasCtrl = StreamController<Ubicacion>.broadcast();
  int lecturasPedidas = 0;

  @override
  Future<MotivoSinUbicacion?> prepararPermiso() => permisoPendiente?.future ?? Future.value(permiso);

  @override
  Stream<Ubicacion> lecturas() {
    lecturasPedidas++;
    return lecturasCtrl.stream;
  }
}

void main() {
  group('FiltroUbicacion', () {
    test('MF-05 descarta una lectura vieja', () {
      expect(FiltroUbicacion().evaluar(_lectura(edad: const Duration(seconds: 11)), _t0), ResultadoFiltro.vieja);
      expect(FiltroUbicacion().evaluar(_lectura(edad: const Duration(seconds: 9)), _t0), ResultadoFiltro.nueva);
    });

    test('MF-06 descarta una lectura imprecisa (> 30 m)', () {
      expect(FiltroUbicacion().evaluar(_lectura(precision: 45), _t0), ResultadoFiltro.imprecisa);
      expect(FiltroUbicacion().evaluar(_lectura(precision: 25), _t0), ResultadoFiltro.nueva);
    });

    test('MF-06 una lectura a menos de 5 m de la anterior es ruido, no movimiento', () {
      final filtro = FiltroUbicacion();
      expect(filtro.evaluar(_lectura(), _t0), ResultadoFiltro.nueva);
      expect(filtro.evaluar(_lectura(dLat: 0.00002), _t0), ResultadoFiltro.sinMovimiento); // ~2 m
      expect(filtro.evaluar(_lectura(dLat: 0.0001), _t0), ResultadoFiltro.nueva); // ~11 m
    });

    test('distanciaM: 0,0001° de latitud son unos 11 m', () {
      expect(FiltroUbicacion.distanciaM(10.37, -75.46, 10.3701, -75.46), closeTo(11.1, 0.1));
    });
  });

  group('UbicacionServiceGps', () {
    test('emite las lecturas válidas y calla el ruido', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        final servicio = UbicacionServiceGps(fuente: fuente, reloj: () => _t0);
        final recibidas = <Ubicacion>[];
        servicio.ubicacionStream.listen(recibidas.add);
        async.flushMicrotasks();

        fuente.lecturasCtrl
          ..add(_lectura())
          ..add(_lectura(dLat: 0.00002)) // ruido
          ..add(_lectura(precision: 80)) // imprecisa
          ..add(_lectura(dLat: 0.0001));
        async.flushMicrotasks();

        expect(recibidas, hasLength(2));
        expect(recibidas.last.lat, closeTo(10.3701, 1e-9));
        servicio.dispose();
      });
    });

    test('MF-04 sin permiso emite UbicacionNoDisponible(permisoDenegado)', () {
      fakeAsync((async) {
        final servicio = UbicacionServiceGps(fuente: _FuenteFalsa(permiso: MotivoSinUbicacion.permisoDenegado));
        final errores = <Object>[];
        servicio.ubicacionStream.listen((_) {}, onError: errores.add);
        async.flushMicrotasks();

        expect(errores.single, isA<UbicacionNoDisponible>()
            .having((e) => e.motivo, 'motivo', MotivoSinUbicacion.permisoDenegado));
        servicio.dispose();
      });
    });

    test('MF-06 solo lecturas imprecisas por 15 s: precisionBaja con el error, y la siguiente válida lo levanta', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        var ahora = _t0;
        final servicio = UbicacionServiceGps(fuente: fuente, reloj: () => ahora);
        final recibidas = <Ubicacion>[];
        final errores = <Object>[];
        servicio.ubicacionStream.listen(recibidas.add, onError: errores.add);
        async.flushMicrotasks();

        fuente.lecturasCtrl.add(_lectura());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 14));
        expect(errores, isEmpty);

        fuente.lecturasCtrl.add(_lectura(precision: 90)); // no cuenta como señal
        async.elapse(const Duration(seconds: 2));
        expect(errores.single, isA<UbicacionNoDisponible>()
            .having((e) => e.motivo, 'motivo', MotivoSinUbicacion.precisionBaja)
            .having((e) => e.precisionM, 'precisionM', 90));

        // El usuario no se movió, pero la señal volvió: se emite para salir del error.
        ahora = _t0.add(const Duration(seconds: 16));
        fuente.lecturasCtrl.add(_lectura(dLat: 0.00001, ahora: ahora));
        async.flushMicrotasks();
        expect(recibidas, hasLength(2));
        servicio.dispose();
      });
    });

    test('MF-04 estar quieto con buena señal no cuenta como sin señal', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        var ahora = _t0;
        final servicio = UbicacionServiceGps(fuente: fuente, reloj: () => ahora);
        final errores = <Object>[];
        servicio.ubicacionStream.listen((_) {}, onError: errores.add);
        async.flushMicrotasks();

        for (var i = 0; i < 6; i++) {
          fuente.lecturasCtrl.add(_lectura(ahora: ahora));
          async.elapse(const Duration(seconds: 5));
          ahora = ahora.add(const Duration(seconds: 5));
        }
        expect(errores, isEmpty);
        servicio.dispose();
      });
    });

    test('MF-04 sin ninguna lectura en 15 s tras una válida emite sinSenal', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        final servicio = UbicacionServiceGps(fuente: fuente, reloj: () => _t0);
        final errores = <Object>[];
        servicio.ubicacionStream.listen((_) {}, onError: errores.add);
        async.flushMicrotasks();

        fuente.lecturasCtrl.add(_lectura());
        async.elapse(const Duration(seconds: 16));
        expect((errores.single as UbicacionNoDisponible).motivo, MotivoSinUbicacion.sinSenal);
        servicio.dispose();
      });
    });

    test('MF-04 la primera lectura tiene 45 s: el aviso de permiso y el arranque en frío tardan', () {
      fakeAsync((async) {
        final servicio = UbicacionServiceGps(fuente: _FuenteFalsa());
        final errores = <Object>[];
        servicio.ubicacionStream.listen((_) {}, onError: errores.add);
        async.elapse(const Duration(seconds: 30));
        expect(errores, isEmpty);
        async.elapse(const Duration(seconds: 16));
        expect(errores, hasLength(1));
        servicio.dispose();
      });
    });

    test('una pantalla que se suscribe después recibe de inmediato la última posición', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        final servicio = UbicacionServiceGps(fuente: fuente, reloj: () => _t0);
        servicio.ubicacionStream.listen((_) {}); // la pantalla vieja sigue suscrita
        async.flushMicrotasks();
        fuente.lecturasCtrl.add(_lectura());
        async.flushMicrotasks();

        final nueva = <Ubicacion>[];
        servicio.ubicacionStream.listen(nueva.add);
        async.flushMicrotasks();
        expect(nueva, hasLength(1));
        servicio.dispose();
      });
    });

    test('al volver a escuchar sin haberse movido, la primera lectura se emite', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        var ahora = _t0;
        final servicio = UbicacionServiceGps(fuente: fuente, reloj: () => ahora);
        final primera = servicio.ubicacionStream.listen((_) {});
        async.flushMicrotasks();
        fuente.lecturasCtrl.add(_lectura());
        async.flushMicrotasks();
        primera.cancel(); // el usuario cambia de pestaña: se apaga el sensor
        async.flushMicrotasks();

        ahora = _t0.add(const Duration(minutes: 5)); // la última ya es vieja: no se repite
        final recibidas = <Ubicacion>[];
        servicio.ubicacionStream.listen(recibidas.add);
        async.flushMicrotasks();
        expect(recibidas, isEmpty);
        fuente.lecturasCtrl.add(_lectura(ahora: ahora)); // mismo lugar
        async.flushMicrotasks();
        expect(recibidas, hasLength(1));
        servicio.dispose();
      });
    });

    test('si se deja de escuchar mientras se espera el permiso, no queda una lectura huérfana', () {
      fakeAsync((async) {
        final permiso = Completer<MotivoSinUbicacion?>();
        final fuente = _FuenteFalsa(permisoPendiente: permiso);
        final servicio = UbicacionServiceGps(fuente: fuente);
        final primera = servicio.ubicacionStream.listen((_) {});
        async.flushMicrotasks();
        primera.cancel();
        async.flushMicrotasks();
        servicio.ubicacionStream.listen((_) {});
        async.flushMicrotasks();

        permiso.complete(null); // el usuario acepta el aviso
        async.flushMicrotasks();
        expect(fuente.lecturasPedidas, 1);
        servicio.dispose();
      });
    });

    test('un error del sensor llega como UbicacionNoDisponible', () {
      fakeAsync((async) {
        final fuente = _FuenteFalsa();
        final servicio = UbicacionServiceGps(fuente: fuente);
        final errores = <Object>[];
        servicio.ubicacionStream.listen((_) {}, onError: errores.add);
        async.flushMicrotasks();

        fuente.lecturasCtrl.addError(const UbicacionNoDisponible(MotivoSinUbicacion.permisoDenegado));
        async.flushMicrotasks();
        expect((errores.single as UbicacionNoDisponible).motivo, MotivoSinUbicacion.permisoDenegado);
        servicio.dispose();
      });
    });
  });
}
