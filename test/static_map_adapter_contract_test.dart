import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';

/// Prueba de contrato para StaticMapAdapter (ficha S7).
///
/// No llama a la red real: usa http.testing.MockClient para simular
/// exactamente las respuestas descritas en
/// docs/api/apis-externas.openapi.yaml (sección Static Maps).
///
/// Cómo producir la evidencia de "la prueba puede fallar" (criterio 7):
/// cambiar temporalmente el content-type simulado abajo de "image/png" a
/// algo inválido (o el status a 400), correr `flutter test`, capturar la
/// corrida en rojo, y revertir. El test "responde ante contenido
/// inválido" ya deja ese caso cubierto como regresión permanente.
void main() {
  final pngFalso = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // firma PNG

  group('StaticMapAdapterHttp — contrato con Google Static Maps API', () {
    test('obtenerImagenMapa traduce una respuesta PNG válida a ImagenMapa', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/maps/api/staticmap');
        expect(request.url.queryParameters['center'], '10.4254,-75.5077');
        expect(request.url.queryParameters['size'], '400x300');
        return http.Response.bytes(pngFalso, 200, headers: {'content-type': 'image/png'});
      });

      final adapter = StaticMapAdapterHttp(apiKey: 'test-key', client: client);
      final imagen = await adapter.obtenerImagenMapa(lat: 10.4254, lng: -75.5077);

      expect(imagen.bytesPng, pngFalso);
      expect(imagen.ancho, 400);
      expect(imagen.alto, 300);
    });

    test('respeta el tamaño y zoom solicitados en los parámetros de la petición', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['zoom'], '18');
        expect(request.url.queryParameters['size'], '200x200');
        return http.Response.bytes(pngFalso, 200, headers: {'content-type': 'image/png'});
      });

      final adapter = StaticMapAdapterHttp(apiKey: 'test-key', client: client);
      await adapter.obtenerImagenMapa(lat: 0, lng: 0, zoom: 18, ancho: 200, alto: 200);
    });

    test('un status distinto de 200 se reporta como StaticMapException, no como bytes inválidos', () async {
      final client = MockClient((request) async {
        return http.Response('Invalid request', 400, headers: {'content-type': 'text/plain'});
      });

      final adapter = StaticMapAdapterHttp(apiKey: 'test-key', client: client);

      expect(
        () => adapter.obtenerImagenMapa(lat: 0, lng: 0),
        throwsA(isA<StaticMapException>()),
      );
    });

    test('un content-type inesperado (no image/*) también se reporta como StaticMapException', () async {
      final client = MockClient((request) async {
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      final adapter = StaticMapAdapterHttp(apiKey: 'test-key', client: client);

      expect(
        () => adapter.obtenerImagenMapa(lat: 0, lng: 0),
        throwsA(isA<StaticMapException>()),
      );
    });
  });
}
