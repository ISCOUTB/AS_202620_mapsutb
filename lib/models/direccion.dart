/// Modelo propio del dominio para el resultado de geocodificación.
///
/// GeocodingAdapter traduce la respuesta de Google Geocoding API a este
/// modelo antes de devolverla — la UI nunca ve el formato de Google
/// directamente (ver docs/arc42/06_runtime_view.md, "Geocodificar una
/// ubicación", y ADR 0001/0002, patrón Adapter).
class Direccion {
  const Direccion({
    required this.texto,
    required this.lat,
    required this.lng,
  });

  /// Dirección legible completa (formatted_address de Google).
  final String texto;
  final double lat;
  final double lng;

  @override
  String toString() => 'Direccion($texto, $lat, $lng)';

  @override
  bool operator ==(Object other) =>
      other is Direccion && other.texto == texto && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(texto, lat, lng);
}
