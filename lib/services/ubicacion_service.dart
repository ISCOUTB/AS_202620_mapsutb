import 'dart:async';
import 'dart:math';
import '../models/ubicacion.dart';

/// Servicio de ubicación (patrón Observer).
///
/// Expone un Stream<Ubicacion> al que cualquier parte de la app puede
/// suscribirse para reaccionar a cambios de posición en tiempo real,
/// sin hacer polling manual (ver ADR 0001/0002). Cuando no hay posición
/// utilizable, el Stream emite un error [UbicacionNoDisponible] y sigue
/// abierto: si la señal vuelve, vuelven las posiciones.
abstract class UbicacionService {
  Stream<Ubicacion> get ubicacionStream;
  void dispose();
}

/// Por qué no hay posición (arc42 §11, MF-04).
enum MotivoSinUbicacion {
  permisoDenegado,
  servicioApagado,
  sinSenal,

  /// Llegan lecturas, pero todas con más error del que sirve en el campus
  /// (típico de un computador que se ubica por Wi-Fi).
  precisionBaja,
}

class UbicacionNoDisponible implements Exception {
  const UbicacionNoDisponible(this.motivo, {this.precisionM});
  final MotivoSinUbicacion motivo;

  /// Con [MotivoSinUbicacion.precisionBaja], el error de la última lectura.
  final double? precisionM;

  @override
  String toString() => 'UbicacionNoDisponible: ${motivo.name}';
}

enum ResultadoFiltro {
  /// Válida y en otro lugar: se emite.
  nueva,

  /// Válida pero a menos de [FiltroUbicacion.minDesplazamientoM]: prueba que
  /// hay señal, pero no se emite.
  sinMovimiento,

  /// Más vieja que [FiltroUbicacion.maxAntiguedad]: como si no hubiera llegado.
  vieja,

  /// Con más error que [FiltroUbicacion.maxPrecisionM]: como si no hubiera llegado.
  imprecisa;

  bool get valida => this == nueva || this == sinMovimiento;
}

/// Decide qué lecturas del sensor se usan (arc42 §11, MF-05 y MF-06).
///
/// - Descarta las viejas: más de [maxAntiguedad] desde que se tomaron.
/// - Descarta las imprecisas: radio de error mayor que [maxPrecisionM]. Los
///   edificios del campus están a unos 20 m entre sí; con más error la
///   ruta empezaría en otro edificio.
/// - Descarta las que se movieron menos de [minDesplazamientoM] desde la
///   última aceptada: es ruido del GPS, no el usuario caminando, y cada una
///   movería el punto y recalcularía la ruta.
class FiltroUbicacion {
  FiltroUbicacion({
    this.maxAntiguedad = const Duration(seconds: 10),
    this.maxPrecisionM = 30,
    this.minDesplazamientoM = 5,
  });

  final Duration maxAntiguedad;
  final double maxPrecisionM;
  final double minDesplazamientoM;

  Ubicacion? _ultima;

  /// Olvida la última lectura aceptada: la siguiente válida cuenta como nueva.
  void reiniciar() => _ultima = null;

  ResultadoFiltro evaluar(Ubicacion u, DateTime ahora) {
    if (ahora.difference(u.timestamp) > maxAntiguedad) return ResultadoFiltro.vieja;
    final precision = u.precisionM;
    if (precision != null && precision > maxPrecisionM) return ResultadoFiltro.imprecisa;
    final ultima = _ultima;
    if (ultima != null && distanciaM(ultima.lat, ultima.lng, u.lat, u.lng) < minDesplazamientoM) {
      return ResultadoFiltro.sinMovimiento;
    }
    _ultima = u;
    return ResultadoFiltro.nueva;
  }

  /// Distancia en metros (equirectangular: sobra a escala de un campus).
  static double distanciaM(double lat1, double lng1, double lat2, double lng2) {
    const radioTierraM = 6371000.0;
    final x = (lng2 - lng1) * pi / 180 * cos((lat1 + lat2) / 2 * pi / 180);
    final y = (lat2 - lat1) * pi / 180;
    return sqrt(x * x + y * y) * radioTierraM;
  }
}

/// Implementación simulada, para demostraciones y pruebas: no usa el GPS.
/// Se activa con `--dart-define=UBICACION_SIMULADA=true` (ver `main.dart`).
/// Emite cada segundo un punto fijo del campus con un ruido de ±1 m, para
/// que el punto no salte por el mapa como antes (±33 m, arc42 §11 MF-06).
class UbicacionServiceSimulado implements UbicacionService {
  // Campus Tecnológico de la UTB (Ternera), entre los edificios A1 y Alcatraz.
  static const double _latBase = 10.37005;
  static const double _lngBase = -75.46545;

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
      final offsetLat = (_random.nextDouble() - 0.5) * 0.00002;
      final offsetLng = (_random.nextDouble() - 0.5) * 0.00002;
      _controller.add(
        Ubicacion(
          lat: _latBase + offsetLat,
          lng: _lngBase + offsetLng,
          timestamp: DateTime.now(),
          precisionM: 5,
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
