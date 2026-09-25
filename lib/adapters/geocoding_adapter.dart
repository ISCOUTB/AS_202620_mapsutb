import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/direccion.dart';

/// Aísla al resto de la app de Google Geocoding API (ADR 0001/0002,
/// patrón Adapter). Ningún tipo de la librería de Google debe usarse
/// fuera de esta clase — quien la consume solo conoce [Direccion].
///
/// Contrato consumido: docs/api/apis-externas.openapi.yaml (sección
/// Geocoding). La correspondencia entre ese contrato y esta
/// implementación se valida en test/geocoding_adapter_contract_test.dart
/// (ficha S7, criterio 3).
abstract class GeocodingAdapter {
  /// Geocodificación inversa: coordenadas -> dirección legible.
  Future<Direccion> geocodificarInversa({required double lat, required double lng});

  /// Geocodificación directa: dirección de texto libre -> coordenadas.
  Future<Direccion> geocodificarDirecta({required String direccion});
}

class GeocodingAdapterHttp implements GeocodingAdapter {
  GeocodingAdapterHttp({required String apiKey, http.Client? client})
      : _apiKey = apiKey,
        _client = client ?? http.Client();

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  final String _apiKey;
  final http.Client _client;

  @override
  Future<Direccion> geocodificarInversa({required double lat, required double lng}) {
    return _geocodificar({'latlng': '$lat,$lng'});
  }

  @override
  Future<Direccion> geocodificarDirecta({required String direccion}) {
    return _geocodificar({'address': direccion});
  }

  Future<Direccion> _geocodificar(Map<String, String> parametrosExtra) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      ...parametrosExtra,
      'key': _apiKey,
    });

    final respuesta = await _client.get(uri);

    // Un error HTTP (5xx, 403 de cuota, página HTML de un proxy) no trae el
    // JSON del contrato: se reporta como GeocodingException en vez de dejar
    // escapar un FormatException de jsonDecode.
    if (respuesta.statusCode != 200) {
      throw GeocodingException('HTTP_${respuesta.statusCode}');
    }

    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;

    final status = cuerpo['status'] as String?;
    if (status != 'OK') {
      throw GeocodingException(status ?? 'UNKNOWN_ERROR');
    }

    final resultados = cuerpo['results'] as List<dynamic>?;
    if (resultados == null || resultados.isEmpty) {
      throw GeocodingException('ZERO_RESULTS');
    }

    // Contrato esperado (docs/api/apis-externas.openapi.yaml): cada resultado
    // trae formatted_address y geometry.location.{lat,lng}. Si Google
    // cambia esta forma de manera incompatible, este cast/acceso falla
    // aquí — es justo lo que valida la prueba de contrato.
    final primero = resultados.first as Map<String, dynamic>;
    final direccionTexto = primero['formatted_address'] as String;
    final ubicacion = (primero['geometry'] as Map<String, dynamic>)['location'] as Map<String, dynamic>;

    return Direccion(
      texto: direccionTexto,
      lat: (ubicacion['lat'] as num).toDouble(),
      lng: (ubicacion['lng'] as num).toDouble(),
    );
  }
}

class GeocodingException implements Exception {
  GeocodingException(this.status);
  final String status;

  @override
  String toString() => 'GeocodingException: Google Geocoding API respondió status=$status';
}
