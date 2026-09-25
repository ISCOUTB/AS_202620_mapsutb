import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/adapters/geocoding_adapter.dart';
import 'package:mapsutb/features/mapas_ruteo/presentation/screens/ubicacion_screen.dart';
import 'package:mapsutb/models/direccion.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

/// Pruebas del servicio de ubicación (patrón Observer) y de su pantalla,
/// incluida la geocodificación inversa con un doble de GeocodingAdapter.

class _UbicacionServiceFalso implements UbicacionService {
  final controller = StreamController<Ubicacion>.broadcast();

  @override
  Stream<Ubicacion> get ubicacionStream => controller.stream;

  @override
  void dispose() => controller.close();
}

class _GeocodingFalso implements GeocodingAdapter {
  _GeocodingFalso({this.falla = false});

  final bool falla;

  @override
  Future<Direccion> geocodificarInversa({
    required double lat,
    required double lng,
  }) async {
    if (falla) throw GeocodingException('HTTP_503');
    return Direccion(texto: 'UTB, Cartagena', lat: lat, lng: lng);
  }

  @override
  Future<Direccion> geocodificarDirecta({required String direccion}) {
    throw UnimplementedError();
  }
}

final _ubicacion = Ubicacion(lat: 10.4254, lng: -75.5077, timestamp: DateTime(2026));

Future<_UbicacionServiceFalso> _montar(
  WidgetTester tester, {
  GeocodingAdapter? geocoding,
}) async {
  final service = _UbicacionServiceFalso();
  addTearDown(service.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: UbicacionScreen(service: service, geocoding: geocoding),
    ),
  ));
  return service;
}

void main() {
  group('UbicacionServiceSimulado', () {
    test('emite posiciones cerca del campus UTB', () async {
      final service = UbicacionServiceSimulado();
      addTearDown(service.dispose);

      final ubicacion = await service.ubicacionStream.first
          .timeout(const Duration(seconds: 5));

      expect(ubicacion.lat, closeTo(10.4254, 0.001));
      expect(ubicacion.lng, closeTo(-75.5077, 0.001));
      expect(ubicacion.toString(), startsWith('lat: 10.42'));
    });
  });

  group('UbicacionScreen', () {
    testWidgets('muestra cada ubicación que emite el Stream', (tester) async {
      final service = await _montar(tester);

      expect(find.text('Esperando señal...'), findsOneWidget);

      service.controller.add(_ubicacion);
      await tester.pump();

      expect(find.text(_ubicacion.toString()), findsOneWidget);
      expect(find.text('Actualizaciones recibidas: 1'), findsOneWidget);
    });

    testWidgets('sin GeocodingAdapter no ofrece "¿Dónde estoy?"',
        (tester) async {
      await _montar(tester);

      expect(find.text('¿Dónde estoy?'), findsNothing);
    });

    testWidgets('"¿Dónde estoy?" muestra la dirección geocodificada',
        (tester) async {
      final service = await _montar(tester, geocoding: _GeocodingFalso());
      service.controller.add(_ubicacion);
      await tester.pump();

      await tester.tap(find.text('¿Dónde estoy?'));
      await tester.pumpAndSettle();

      expect(find.text('UTB, Cartagena'), findsOneWidget);
    });

    testWidgets('si Geocoding falla muestra un mensaje controlado (Escenario 3)',
        (tester) async {
      final service =
          await _montar(tester, geocoding: _GeocodingFalso(falla: true));
      service.controller.add(_ubicacion);
      await tester.pump();

      await tester.tap(find.text('¿Dónde estoy?'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo obtener la dirección. Revisa tu conexión.'),
        findsOneWidget,
      );
    });
  });
}
