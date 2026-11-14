import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/geocoding_adapter.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/features/mapas_ruteo/presentation/screens/ubicacion_screen.dart';
import 'package:mapsutb/models/direccion.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

/// Modos de fallo de las integraciones HTTP (ficha S11, arc42 §11, ADR 0016):
/// el otro lado no responde, responde tarde o responde dos veces. Cada
/// prueba lleva el ID de la fila de la tabla de `docs/arc42/11_technical_risks.adoc`.

const _respuestaValida = '''
{"status": "OK", "results": [{"formatted_address": "UTB, Cartagena",
 "geometry": {"location": {"lat": 10.37, "lng": -75.46}}}]}
''';

const _corto = Duration(milliseconds: 20);

/// Un proveedor lento: contesta bien, pero después del tiempo límite.
MockClient _lento(http.Response respuesta) => MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return respuesta;
    });

Matcher _geocodingCon(String status) =>
    throwsA(isA<GeocodingException>().having((e) => e.status, 'status', status));

class _UbicacionServiceFalso implements UbicacionService {
  final controller = StreamController<Ubicacion>.broadcast();

  @override
  Stream<Ubicacion> get ubicacionStream => controller.stream;

  @override
  void dispose() => controller.close();
}

/// Geocoding que no contesta hasta que la prueba lo decide, y cuenta llamadas.
class _GeocodingPendiente implements GeocodingAdapter {
  final respuesta = Completer<Direccion>();
  int llamadas = 0;

  @override
  Future<Direccion> geocodificarInversa({required double lat, required double lng}) {
    llamadas++;
    return respuesta.future;
  }

  @override
  Future<Direccion> geocodificarDirecta({required String direccion}) => throw UnimplementedError();
}

void main() {
  group('Geocoding (integración principal)', () {
    test('MF-07 no responde: se reporta SIN_CONEXION, no una excepción cruda', () async {
      final client = MockClient((_) async => throw http.ClientException('sin red'));
      final adapter = GeocodingAdapterHttp(apiKey: 'k', client: client);

      await expectLater(adapter.geocodificarInversa(lat: 0, lng: 0), _geocodingCon('SIN_CONEXION'));
    });

    test('MF-08 responde tarde: pasado el tiempo límite se da por fallida', () async {
      final adapter = GeocodingAdapterHttp(
        apiKey: 'k',
        client: _lento(http.Response(_respuestaValida, 200)),
        tiempoLimite: _corto,
      );
      final reloj = Stopwatch()..start();

      await expectLater(adapter.geocodificarInversa(lat: 0, lng: 0), _geocodingCon('TIEMPO_AGOTADO'));
      // Falla por el tiempo límite, no porque esperó la respuesta tardía.
      expect(reloj.elapsedMilliseconds, lessThan(200));
    });

    test('MF-08 no reintenta solo: un tiempo agotado es una sola consulta a la cuota', () async {
      var peticiones = 0;
      final client = MockClient((_) async {
        peticiones++;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(_respuestaValida, 200);
      });
      final adapter = GeocodingAdapterHttp(apiKey: 'k', client: client, tiempoLimite: _corto);

      await expectLater(adapter.geocodificarInversa(lat: 0, lng: 0), throwsA(isA<GeocodingException>()));
      expect(peticiones, 1);
    });

    testWidgets('MF-09 responde dos veces: un segundo toque mientras espera no repite la consulta',
        (tester) async {
      final service = _UbicacionServiceFalso();
      addTearDown(service.dispose);
      final geocoding = _GeocodingPendiente();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: UbicacionScreen(service: service, geocoding: geocoding)),
      ));
      service.controller.add(Ubicacion(lat: 10.37, lng: -75.46, timestamp: DateTime(2026)));
      await tester.pump();

      await tester.tap(find.text('¿Dónde estoy?'));
      await tester.pump();
      await tester.tap(find.text('¿Dónde estoy?'));
      await tester.pump();
      expect(geocoding.llamadas, 1);

      geocoding.respuesta.complete(const Direccion(texto: 'UTB, Cartagena', lat: 10.37, lng: -75.46));
      await tester.pumpAndSettle();
      expect(find.text('UTB, Cartagena'), findsOneWidget);
    });

    testWidgets('MF-08 en pantalla: el tiempo agotado termina en un mensaje controlado (Escenario 3)',
        (tester) async {
      final service = _UbicacionServiceFalso();
      addTearDown(service.dispose);
      final client = MockClient((_) => Completer<http.Response>().future); // nunca contesta
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UbicacionScreen(
            service: service,
            geocoding: GeocodingAdapterHttp(apiKey: 'k', client: client),
          ),
        ),
      ));
      service.controller.add(Ubicacion(lat: 10.37, lng: -75.46, timestamp: DateTime(2026)));
      await tester.pump();

      await tester.tap(find.text('¿Dónde estoy?'));
      await tester.pump(const Duration(seconds: 6));

      expect(find.text('No se pudo obtener la dirección. Revisa tu conexión.'), findsOneWidget);
    });
  });

  group('Static Maps', () {
    test('MF-10 no responde: StaticMapException', () async {
      final client = MockClient((_) async => throw http.ClientException('sin red'));
      final adapter = StaticMapAdapterHttp(apiKey: 'k', client: client);

      await expectLater(adapter.obtenerImagenMapa(lat: 0, lng: 0), throwsA(isA<StaticMapException>()));
    });

    test('MF-11 responde tarde: StaticMapException en vez de esperar sin fin', () async {
      final adapter = StaticMapAdapterHttp(
        apiKey: 'k',
        client: _lento(http.Response.bytes([1], 200, headers: {'content-type': 'image/png'})),
        tiempoLimite: _corto,
      );

      await expectLater(adapter.obtenerImagenMapa(lat: 0, lng: 0), throwsA(isA<StaticMapException>()));
    });
  });

  group('Analítica (Measurement Protocol)', () {
    AnalyticsAdapterHttp adapter(http.Client client) => AnalyticsAdapterHttp(
          measurementId: 'G-TEST',
          apiSecret: 's',
          clientId: 'c',
          client: client,
          tiempoLimite: _corto,
        );
    const evento = EventoAnalitica(nombre: 'solicitud_ruta');

    test('MF-14 responde tarde: el evento se da por perdido sin lanzar', () async {
      await adapter(_lento(http.Response('', 204))).registrarEvento(evento);
    });

    test('MF-15 como máximo una vez: ni un fallo de red ni un tiempo agotado reenvían el evento',
        () async {
      final cuerpos = <String>[];
      final sinRed = MockClient((r) async {
        cuerpos.add(r.body);
        throw http.ClientException('sin red');
      });
      final lento = MockClient((r) async {
        cuerpos.add(r.body);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('', 204);
      });

      await adapter(sinRed).registrarEvento(evento);
      await adapter(lento).registrarEvento(evento);

      expect(cuerpos, hasLength(2)); // uno por llamada, ninguno repetido
      expect((jsonDecode(cuerpos.first) as Map)['events'], hasLength(1));
    });
  });
}
