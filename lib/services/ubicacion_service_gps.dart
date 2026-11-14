import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

import '../core/log.dart';
import '../models/ubicacion.dart';
import 'ubicacion_service.dart';

/// Lo que [UbicacionServiceGps] necesita del sensor. Está separado para
/// probar el servicio sin GPS ni permisos (`test/ubicacion_gps_test.dart`).
abstract class FuenteGps {
  /// Pide permiso si hace falta. Devuelve null si se puede leer la posición.
  Future<MotivoSinUbicacion?> prepararPermiso();

  /// Lecturas del sensor; un fallo llega como [UbicacionNoDisponible].
  Stream<Ubicacion> lecturas();
}

/// Fuente real con `geolocator`: en la web usa la API de geolocalización
/// del navegador, que solo funciona con HTTPS (Firebase Hosting lo da).
class FuenteGeolocator implements FuenteGps {
  const FuenteGeolocator();

  @override
  Future<MotivoSinUbicacion?> prepararPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) return MotivoSinUbicacion.servicioApagado;
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.deniedForever) return MotivoSinUbicacion.permisoDenegado;
    // En la web, requestPermission pide una posición sin tiempo límite y
    // convierte cualquier fallo en «denegado para siempre». Allí el aviso
    // del navegador lo dispara la propia lectura, y una negativa llega como
    // PermissionDeniedException en el Stream.
    if (kIsWeb) return null;
    if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return MotivoSinUbicacion.permisoDenegado;
    }
    return null;
  }

  @override
  Stream<Ubicacion> lecturas() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      ).transform(StreamTransformer.fromHandlers(
        handleData: (p, sink) => sink.add(Ubicacion(
          lat: p.latitude,
          lng: p.longitude,
          timestamp: p.timestamp,
          precisionM: p.accuracy,
        )),
        handleError: (e, st, sink) => sink.addError(UbicacionNoDisponible(
          e is PermissionDeniedException ? MotivoSinUbicacion.permisoDenegado : MotivoSinUbicacion.sinSenal,
        )),
      ));
}

/// Posición real del dispositivo (A-01, Escenario 2), con los modos de fallo
/// del sensor resueltos aquí (arc42 §11):
///
/// - MF-04 no responde: sin permiso, con la ubicación apagada o sin una
///   lectura válida a tiempo, emite [UbicacionNoDisponible] con el motivo.
/// - MF-05 responde tarde y MF-06 responde con ruido: [FiltroUbicacion]
///   descarta lecturas viejas, imprecisas o que no se movieron.
///
/// Cada pantalla que se suscribe recibe de inmediato el último estado
/// conocido (la última lectura válida, si es reciente, o el último fallo):
/// el Stream es broadcast y sin esto una pantalla nueva esperaría a que el
/// usuario se moviera 5 m.
class UbicacionServiceGps implements UbicacionService {
  UbicacionServiceGps({
    FuenteGps fuente = const FuenteGeolocator(),
    FiltroUbicacion? filtro,
    this.tiempoSinSenal = const Duration(seconds: 15),
    this.tiempoPrimeraLectura = const Duration(seconds: 45),
    DateTime Function()? reloj,
  })  : _fuente = fuente,
        _filtro = filtro ?? FiltroUbicacion(),
        _reloj = reloj ?? DateTime.now {
    _controller = StreamController<Ubicacion>.broadcast(onListen: _iniciar, onCancel: _detener);
  }

  final FuenteGps _fuente;
  final FiltroUbicacion _filtro;
  final DateTime Function() _reloj;

  /// Sin lectura válida durante este tiempo, se avisa la falta de señal.
  final Duration tiempoSinSenal;

  /// Plazo para la primera lectura: incluye el aviso de permiso del
  /// navegador, que el usuario puede tardar en responder, y el arranque en
  /// frío del GPS.
  final Duration tiempoPrimeraLectura;

  late final StreamController<Ubicacion> _controller;
  StreamSubscription<Ubicacion>? _lecturas;
  Timer? _vigia;

  /// Cambia en cada inicio y en cada detención: un [_iniciar] que vuelve de
  /// esperar el permiso después de un [_detener] ya no es el vigente.
  int _generacion = 0;

  /// Última lectura válida (aunque no se haya emitido por no moverse).
  Ubicacion? _ultimaValida;

  /// Último fallo emitido; null mientras hay posición.
  UbicacionNoDisponible? _fallo;

  /// Error de la última lectura descartada por imprecisa desde la última
  /// válida, para distinguir «sin señal» de «señal demasiado imprecisa».
  double? _imprecisionReciente;

  @override
  Stream<Ubicacion> get ubicacionStream => Stream<Ubicacion>.multi((oyente) {
        final fallo = _fallo;
        final ultima = _ultimaValida;
        if (fallo != null) {
          oyente.addError(fallo);
        } else if (ultima != null && _reloj().difference(ultima.timestamp) <= _filtro.maxAntiguedad) {
          oyente.add(ultima);
        }
        final sub = _controller.stream.listen(oyente.add, onError: oyente.addError, onDone: oyente.close);
        oyente.onCancel = sub.cancel;
      }, isBroadcast: true);

  Future<void> _iniciar() async {
    final generacion = ++_generacion;
    MotivoSinUbicacion? motivo;
    try {
      motivo = await _fuente.prepararPermiso();
    } catch (_) {
      motivo = MotivoSinUbicacion.servicioApagado; // p. ej. plataforma sin GPS
    }
    if (generacion != _generacion) return;
    if (motivo != null) {
      _fallar(UbicacionNoDisponible(motivo));
      return;
    }
    _armarVigia(_ultimaValida == null ? tiempoPrimeraLectura : tiempoSinSenal);
    _lecturas = _fuente.lecturas().listen(
      _recibir,
      onError: (Object e) => _fallar(
          e is UbicacionNoDisponible ? e : const UbicacionNoDisponible(MotivoSinUbicacion.sinSenal)),
    );
  }

  void _recibir(Ubicacion u) {
    final resultado = _filtro.evaluar(u, _reloj());
    if (resultado == ResultadoFiltro.imprecisa) _imprecisionReciente = u.precisionM;
    if (!resultado.valida) return;
    _ultimaValida = u;
    _imprecisionReciente = null;
    _armarVigia(tiempoSinSenal); // la señal está viva aunque el usuario esté quieto
    // Tras un fallo, la siguiente lectura válida se emite aunque no se haya
    // movido, para que la pantalla salga del error.
    if (resultado == ResultadoFiltro.nueva || _fallo != null) {
      _fallo = null;
      _controller.add(u);
    }
  }

  void _armarVigia(Duration plazo) {
    _vigia?.cancel();
    _vigia = Timer(plazo, () {
      final imprecision = _imprecisionReciente;
      _fallar(imprecision == null
          ? const UbicacionNoDisponible(MotivoSinUbicacion.sinSenal)
          : UbicacionNoDisponible(MotivoSinUbicacion.precisionBaja, precisionM: imprecision));
    });
  }

  void _fallar(UbicacionNoDisponible fallo) {
    if (_controller.isClosed) return;
    _fallo = fallo;
    Log.warn('ubicacion_no_disponible', {'motivo': fallo.motivo.name});
    _controller.addError(fallo);
  }

  /// Nadie escucha: se apaga el sensor. Al volver, la primera lectura válida
  /// se emite aunque el usuario no se haya movido.
  void _detener() {
    _generacion++;
    _vigia?.cancel();
    _lecturas?.cancel();
    _lecturas = null;
    _filtro.reiniciar();
    // Un permiso negado se sigue mostrando al volver; la falta de señal se
    // vuelve a comprobar con el sensor encendido.
    if (_fallo?.motivo != MotivoSinUbicacion.permisoDenegado) _fallo = null;
  }

  @override
  void dispose() {
    _detener();
    _controller.close();
  }
}
