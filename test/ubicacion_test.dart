import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/adapters/geocoding_adapter.dart';
import 'package:mapsutb/features/mapas_ruteo/presentation/screens/ubicacion_screen.dart';
import 'package:mapsutb/models/direccion.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
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

class _ZonasFalsas implements ZonaRepository {
  @override
  Future<List<Zona>> obtenerPuntos() async => [
        Zona(id: 'a2', nombre: 'A2', tipo: 'edificio', lat: 10.3700, lng: -75.4660),
        Zona(id: 'biblioteca', nombre: 'Biblioteca', tipo: 'edificio', lat: 10.3690, lng: -75.4650),
        Zona(id: 'contenedores', nombre: 'Contenedores', tipo: 'servicio', lat: 0, lng: 0),
      ];
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

      expect(ubicacion.lat, closeTo(10.37005, 0.001));
      expect(ubicacion.lng, closeTo(-75.46545, 0.001));
      // El desplazamiento aleatorio puede dar 10.369… o 10.370…: se valida el formato.
      expect(ubicacion.toString(), matches(RegExp(r'^lat: 10\.3[67]\d{3}, lng: -75\.46\d{3}$')));
    });
  });

  group('UbicacionScreen', () {
    testWidgets('muestra cada ubicación que emite el Stream', (tester) async {
      final service = await _montar(tester);

      expect(find.text('Esperando tu ubicación…'), findsOneWidget);

      service.controller.add(_ubicacion);
      await tester.pump();

      // Sin catálogo de zonas, muestra las coordenadas.
      expect(find.text(_ubicacion.toString()), findsOneWidget);
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

  group('UbicacionScreen con GPS real', () {
    testWidgets('muestra la precisión que declara el sensor', (tester) async {
      final service = await _montar(tester);
      service.controller.add(Ubicacion(lat: 10.37, lng: -75.46, timestamp: DateTime(2026), precisionM: 7.6));
      await tester.pumpAndSettle();

      expect(find.text('± 8 m'), findsOneWidget);
      expect(find.textContaining('simulada'), findsNothing);
    });

    testWidgets('dice la zona más cercana en vez de coordenadas', (tester) async {
      final service = _UbicacionServiceFalso();
      addTearDown(service.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: UbicacionScreen(service: service, zonaRepository: _ZonasFalsas())),
      ));
      await tester.pumpAndSettle();

      // ~33 m al norte de A2.
      service.controller.add(Ubicacion(lat: 10.3703, lng: -75.4660, timestamp: DateTime(2026), precisionM: 6));
      await tester.pumpAndSettle();
      expect(find.text('Estás cerca de A2'), findsOneWidget);
      expect(find.text('a 33 m · ± 6 m'), findsOneWidget);

      service.controller.add(Ubicacion(lat: 10.4254, lng: -75.5077, timestamp: DateTime(2026))); // sede Manga
      await tester.pumpAndSettle();
      expect(find.text('Estás fuera del campus'), findsOneWidget);
    });

    testWidgets('MF-06 con precisión baja explica por qué y qué hacer', (tester) async {
      final service = await _montar(tester);
      service.controller.addError(const UbicacionNoDisponible(MotivoSinUbicacion.precisionBaja, precisionM: 1200));
      await tester.pumpAndSettle();
      expect(find.textContaining('demasiado imprecisa (± 1200 m)'), findsOneWidget);
    });

    testWidgets('MF-04 sin señal lo explica, y una lectura nueva lo quita', (tester) async {
      final service = await _montar(tester);
      service.controller.addError(const UbicacionNoDisponible(MotivoSinUbicacion.sinSenal));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sin_ubicacion')), findsOneWidget);

      service.controller.add(_ubicacion);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sin_ubicacion')), findsNothing);
    });
  });
}
