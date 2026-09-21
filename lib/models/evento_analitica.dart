/// Modelo propio del dominio para un evento de analítica de uso.
///
/// AnalyticsAdapter traduce este modelo al formato que exige el
/// Measurement Protocol de Firebase/Google Analytics antes de enviarlo —
/// el resto de la app nunca construye el payload del proveedor
/// directamente (ver ADR 0005, patrón Adapter).
class EventoAnalitica {
  const EventoAnalitica({
    required this.nombre,
    this.parametros = const {},
  });

  /// Nombre del evento (p. ej. "ruta_trazada", "tour_iniciado").
  final String nombre;

  /// Parámetros adicionales del evento (claves y valores simples).
  final Map<String, Object?> parametros;

  @override
  String toString() => 'EventoAnalitica($nombre, $parametros)';
}
