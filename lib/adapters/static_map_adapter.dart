import 'package:http/http.dart' as http;

import '../models/imagen_mapa.dart';

/// Aísla al resto de la app de Google Static Maps API (ADR 0001/0002,
/// patrón Adapter). Se usa para generar miniaturas/preview estáticos de
/// una ubicación (p. ej. una tarjeta de punto de interés o el resultado
/// de "compartir ubicación") — la vista interactiva del mapa sigue
/// usando el SDK embebido de Google Maps (MapaWidget), que no expone
/// una llamada REST propia y por eso no forma parte de este contrato.
///
/// Contrato consumido: docs/api/apis-externas.openapi.yaml (sección
/// Static Maps). La correspondencia entre ese contrato y esta
/// implementación se valida en
/// test/static_map_adapter_contract_test.dart (ficha S7, criterio 3).
abstract class StaticMapAdapter {
  /// Genera una imagen estática centrada en [lat]/[lng].
  Future<ImagenMapa> obtenerImagenMapa({
    required double lat,
    required double lng,
    int zoom = 16,
    int ancho = 400,
    int alto = 300,
  });
}

class StaticMapAdapterHttp implements StaticMapAdapter {
  StaticMapAdapterHttp({required String apiKey, http.Client? client})
      : _apiKey = apiKey,
        _client = client ?? http.Client();

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';

  final String _apiKey;
  final http.Client _client;

  @override
  Future<ImagenMapa> obtenerImagenMapa({
    required double lat,
    required double lng,
    int zoom = 16,
    int ancho = 400,
    int alto = 300,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'center': '$lat,$lng',
      'zoom': '$zoom',
      'size': '${ancho}x$alto',
      'maptype': 'roadmap',
      'key': _apiKey,
    });

    final respuesta = await _client.get(uri);

    // Contrato esperado (docs/api/apis-externas.openapi.yaml): 200 con
    // Content-Type image/png y el cuerpo crudo de la imagen. Cualquier
    // otro caso (error del proveedor, cuota agotada, key inválida) se
    // reporta como StaticMapException en vez de propagar bytes basura.
    if (respuesta.statusCode != 200 ||
        !(respuesta.headers['content-type']?.startsWith('image/') ?? false)) {
      throw StaticMapException(respuesta.statusCode, respuesta.headers['content-type']);
    }

    return ImagenMapa(bytesPng: respuesta.bodyBytes, ancho: ancho, alto: alto);
  }
}

class StaticMapException implements Exception {
  StaticMapException(this.statusCode, this.contentType);
  final int statusCode;
  final String? contentType;

  @override
  String toString() =>
      'StaticMapException: Google Static Maps API respondió statusCode=$statusCode content-type=$contentType';
}
