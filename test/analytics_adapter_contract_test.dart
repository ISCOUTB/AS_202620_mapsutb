import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/models/evento_analitica.dart';

/// Prueba de contrato para AnalyticsAdapter (ficha S7).
///
/// No llama a la red real: usa http.testing.MockClient para simular
/// exactamente las respuestas descritas en
/// docs/api/apis-externas.openapi.yaml (sección Measurement Protocol).
///
/// Cómo producir la evidencia de "la prueba puede fallar" (criterio 7):
/// cambiar temporalmente el status simulado de 204 a otro valor y quitar
/// el manejo de errores de red, correr `flutter test`, capturar la
/// corrida en rojo, y revertir. El test "reporta un status inesperado
/// como AnalyticsException" ya deja ese caso cubierto como regresión
/// permanente.
void main() {
  group('AnalyticsAdapterHttp — contrato con Measurement Protocol', () {
    test('registrarEvento arma la petición según el contrato y acepta 204', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/mp/collect');
        expect(request.url.queryParameters['measurement_id'], 'G-TEST');
        expect(request.url.queryParameters['api_secret'], 'secret-test');

        final cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
        expect(cuerpo['client_id'], 'device-123');
        final eventos = cuerpo['events'] as List<dynamic>;
        expect((eventos.first as Map<String, dynamic>)['name'], 'ruta_trazada');

        return http.Response('', 204);
      });

      final adapter = AnalyticsAdapterHttp(
        measurementId: 'G-TEST',
        apiSecret: 'secret-test',
        clientId: 'device-123',
        client: client,
      );

      await adapter.registrarEvento(
        const EventoAnalitica(nombre: 'ruta_trazada', parametros: {'zona_destino': 'A1'}),
      );
    });

    test('reporta un status inesperado como AnalyticsException', () async {
      final client = MockClient((request) async {
        return http.Response('', 500);
      });

      final adapter = AnalyticsAdapterHttp(
        measurementId: 'G-TEST',
        apiSecret: 'secret-test',
        clientId: 'device-123',
        client: client,
      );

      expect(
        () => adapter.registrarEvento(const EventoAnalitica(nombre: 'tour_iniciado')),
        throwsA(isA<AnalyticsException>()),
      );
    });

    test('un fallo de red no interrumpe el flujo principal (Escenario 3)', () async {
      final client = MockClient((request) async {
        throw  http.ClientException('sin conexión');
      });

      final adapter = AnalyticsAdapterHttp(
        measurementId: 'G-TEST',
        apiSecret: 'secret-test',
        clientId: 'device-123',
        client: client,
      );

      // No debe lanzar: la analítica es de mejor esfuerzo.
      await adapter.registrarEvento(const EventoAnalitica(nombre: 'tour_iniciado'));
    });
  });
}
