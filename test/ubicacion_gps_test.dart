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
  _FuenteFalsa({this.permiso});
  final MotivoSinUbicacion? permiso;
  final lecturasCtrl = StreamController<Ubicacion>();

  @override
  Future<MotivoSinUbicacion?> prepararPermiso() async => permiso;

  @override
  Stream<Ubicacion> lecturas() => lecturasCtrl.stream;
}

void main() {
  group('FiltroUbicacion', () {
    test('MF-05 descarta una lectura vieja', () {
      expect(FiltroUbicacion().evaluar(_lectura(edad: const Duration(seconds: 11)), _t0), ResultadoFiltro.descartada);
      expect(FiltroUbicacion().evaluar(_lectura(edad: const Duration(seconds: 9)), _t0), ResultadoFiltro.nueva);
    });

    test('MF-06 descarta una lectura imprecisa (> 30 m)', () {
      expect(FiltroUbicacion().evaluar(_lectura(precision: 45), _t0), ResultadoFiltro.descartada);
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

    test('MF-04 sin lecturas válidas en 15 s emite sinSenal, y la siguiente lectura lo levanta', () {
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
            .having((e) => e.motivo, 'motivo', MotivoSinUbicacion.sinSenal));

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
