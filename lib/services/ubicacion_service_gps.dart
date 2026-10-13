import 'dart:async';

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
///   lectura válida en [tiempoSinSenal], emite [UbicacionNoDisponible].
/// - MF-05 responde tarde y MF-06 responde con ruido: [FiltroUbicacion]
///   descarta lecturas viejas, imprecisas o que no se movieron.
class UbicacionServiceGps implements UbicacionService {
  UbicacionServiceGps({
    FuenteGps fuente = const FuenteGeolocator(),
    FiltroUbicacion? filtro,
    this.tiempoSinSenal = const Duration(seconds: 15),
    DateTime Function()? reloj,
  })  : _fuente = fuente,
        _filtro = filtro ?? FiltroUbicacion(),
        _reloj = reloj ?? DateTime.now {
    _controller = StreamController<Ubicacion>.broadcast(onListen: _iniciar, onCancel: _detener);
  }

  final FuenteGps _fuente;
  final FiltroUbicacion _filtro;
  final DateTime Function() _reloj;
  final Duration tiempoSinSenal;

  late final StreamController<Ubicacion> _controller;
  StreamSubscription<Ubicacion>? _lecturas;
  Timer? _vigia;
  bool _activo = false;

  /// Después de un fallo, la siguiente lectura válida se emite aunque el
  /// usuario no se haya movido, para que la pantalla salga del error.
  bool _enFallo = false;

  @override
  Stream<Ubicacion> get ubicacionStream => _controller.stream;

  Future<void> _iniciar() async {
    _activo = true;
    _armarVigia();
    MotivoSinUbicacion? motivo;
    try {
      motivo = await _fuente.prepararPermiso();
    } catch (_) {
      motivo = MotivoSinUbicacion.servicioApagado; // p. ej. plataforma sin GPS
    }
    if (!_activo) return;
    if (motivo != null) {
      _vigia?.cancel();
      _fallar(motivo);
      return;
    }
    _lecturas = _fuente.lecturas().listen(
      _recibir,
      onError: (Object e) => _fallar(e is UbicacionNoDisponible ? e.motivo : MotivoSinUbicacion.sinSenal),
    );
  }

  void _recibir(Ubicacion u) {
    final resultado = _filtro.evaluar(u, _reloj());
    if (resultado == ResultadoFiltro.descartada) return;
    _armarVigia(); // la señal está viva aunque el usuario esté quieto
    if (resultado == ResultadoFiltro.nueva || _enFallo) {
      _enFallo = false;
      _controller.add(u);
    }
  }

  void _armarVigia() {
    _vigia?.cancel();
    _vigia = Timer(tiempoSinSenal, () => _fallar(MotivoSinUbicacion.sinSenal));
  }

  void _fallar(MotivoSinUbicacion motivo) {
    if (_controller.isClosed) return;
    _enFallo = true;
    Log.warn('ubicacion_no_disponible', {'motivo': motivo.name});
    _controller.addError(UbicacionNoDisponible(motivo));
  }

  void _detener() {
    _activo = false;
    _vigia?.cancel();
    _lecturas?.cancel();
    _lecturas = null;
  }

  @override
  void dispose() {
    _detener();
    _controller.close();
  }
}
