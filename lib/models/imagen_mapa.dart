/// Modelo propio del dominio para una imagen de mapa estática (miniatura).
///
/// StaticMapAdapter traduce la respuesta binaria de Google Static Maps API
/// a este modelo antes de devolverla — la UI nunca maneja bytes crudos ni
/// tipos de la librería de Google directamente (ver ADR 0005, patrón
/// Adapter).
class ImagenMapa {
  const ImagenMapa({
    required this.bytesPng,
    required this.ancho,
    required this.alto,
  });

  /// Contenido de la imagen en formato PNG, tal como lo entrega el
  /// proveedor (Google Static Maps API).
  final List<int> bytesPng;
  final int ancho;
  final int alto;

  @override
  String toString() => 'ImagenMapa(${bytesPng.length} bytes, ${ancho}x$alto)';
}
