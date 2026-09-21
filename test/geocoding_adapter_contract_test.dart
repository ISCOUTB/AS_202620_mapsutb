import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapsutb/adapters/geocoding_adapter.dart';

/// Prueba de contrato para GeocodingAdapter (ficha S7).
///
/// No llama a la red real: usa http.testing.MockClient para simular
/// exactamente las respuestas descritas en docs/api/geocoding.openapi.yaml,
/// y valida que GeocodingAdapter las traduce al modelo Direccion tal como
/// dice docs/arc42/06_runtime_view.md ("Geocodificar una ubicación").
///
/// Cómo producir la evidencia de "la prueba puede fallar" que pide la
/// ficha (criterio 7): antes del cierre, cambiar temporalmente el fixture
/// de abajo (por ejemplo, renombrar "formatted_address" a "address" como
/// si Google hubiera roto el contrato), correr `flutter test`, capturar
/// la corrida en rojo (local o el run de CI), y luego revertir el cambio.
/// El test "responde ante una respuesta incompatible" ya deja este caso
/// cubierto como regresión permanente, pero la ficha pide ver la corrida
/// en rojo en el historial, no solo la aserción.
void main() {
  const respuestaValida = '''
{
  "status": "OK",
  "results": [
    {
      "formatted_address": "Universidad Tecnológica de Bolívar, Cra. 21 #25-92, Cartagena, Colombia",
      "geometry": {
        "location": { "lat": 10.42540, "lng": -75.50770 }
      }
    }
  ]
}
''';

  group('GeocodingAdapterHttp — contrato con Google Geocoding API', () {
    test('geocodificarInversa traduce una respuesta válida a Direccion', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/maps/api/geocode/json');
        expect(request.url.queryParameters['latlng'], '10.4254,-75.5077');
        return http.Response(respuestaValida, 200);
      });

      final adapter = GeocodingAdapterHttp(apiKey: 'test-key', client: client);
      final direccion = await adapter.geocodificarInversa(lat: 10.4254, lng: -75.5077);

      expect(direccion.texto, contains('Universidad Tecnológica de Bolívar'));
      expect(direccion.lat, closeTo(10.42540, 0.0001));
      expect(direccion.lng, closeTo(-75.50770, 0.0001));
    });

    test('geocodificarDirecta traduce dirección de texto a coordenadas', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['address'], isNotNull);
        return http.Response(respuestaValida, 200);
      });

      final adapter = GeocodingAdapterHttp(apiKey: 'test-key', client: client);
      final direccion = await adapter.geocodificarDirecta(direccion: 'UTB, Cartagena');

      expect(direccion.lat, closeTo(10.42540, 0.0001));
    });

    test('reporta status distinto de OK como GeocodingException, no como excepción cruda', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'ZERO_RESULTS', 'results': []}), 200);
      });

      final adapter = GeocodingAdapterHttp(apiKey: 'test-key', client: client);

      expect(
        () => adapter.geocodificarInversa(lat: 0, lng: 0),
        throwsA(isA<GeocodingException>()),
      );
    });

    test(
      'una respuesta incompatible con el contrato (campo renombrado) rompe la '
      'traducción en vez de fallar silenciosamente',
      () async {
        // Simula que Google (o cualquier proveedor futuro) cambió
        // "formatted_address" por "address" de forma incompatible.
        const respuestaIncompatible = '''
        {
          "status": "OK",
          "results": [
            { "address": "algo", "geometry": { "location": { "lat": 1, "lng": 2 } } }
          ]
        }
        ''';
        final client = MockClient((request) async {
          return http.Response(respuestaIncompatible, 200);
        });

        final adapter = GeocodingAdapterHttp(apiKey: 'test-key', client: client);

        expect(
          () => adapter.geocodificarInversa(lat: 0, lng: 0),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });
}
