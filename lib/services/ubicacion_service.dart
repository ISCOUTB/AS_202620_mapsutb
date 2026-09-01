import 'dart:async';
import 'dart:math';
import '../models/ubicacion.dart';

/// Servicio de ubicación (patrón Observer).
///
/// Expone un Stream<Ubicacion> al que cualquier parte de la app puede
/// suscribirse para reaccionar a cambios de posición en tiempo real,
/// sin hacer polling manual (ver ADR 0001/0002).
abstract class UbicacionService {
  Stream<Ubicacion> get ubicacionStream;
  void dispose();
}

/// Implementación simulada: todavía no usa GPS real ni el paquete
/// `geolocator`. Emite una posición nueva cada segundo, con un pequeño
/// desplazamiento aleatorio alrededor de un punto fijo del campus UTB,
/// para demostrar el patrón Observer sin depender de hardware ni
/// permisos de ubicación. El día que se integre `geolocator`, solo se
/// reemplaza esta clase por una que escuche el sensor real — el resto
/// de la app (que solo conoce `UbicacionService`) no cambia.
class UbicacionServiceSimulado implements UbicacionService {
  static const double _latBase = 10.42540; // UTB, Cartagena (aprox.)
  static const double _lngBase = -75.50770;

  final _random = Random();
  late final StreamController<Ubicacion> _controller;
  Timer? _timer;

  UbicacionServiceSimulado() {
    _controller = StreamController<Ubicacion>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  @override
  Stream<Ubicacion> get ubicacionStream => _controller.stream;

  void _start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final offsetLat = (_random.nextDouble() - 0.5) * 0.0006;
      final offsetLng = (_random.nextDouble() - 0.5) * 0.0006;
      _controller.add(
        Ubicacion(
          lat: _latBase + offsetLat,
          lng: _lngBase + offsetLng,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
