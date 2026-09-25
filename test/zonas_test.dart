import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/features/zonas/presentation/screens/zonas_screen.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/imagen_mapa.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';

/// Pruebas del catálogo de zonas: modelo, Repository y pantallas
/// (lista + detalle), con dobles de prueba para las APIs externas.

// PNG válido de 1x1, para que Image.memory no falle al decodificar.
final _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Zona _zonaDePrueba({double lat = 0, double lng = 0}) => Zona.fromJson({
      'id': 'a1',
      'nombre': 'Edificio A1',
      'tipo': 'edificio',
      'lat': lat,
      'lng': lng,
      'pisos': [
        {'id': 'p1', 'nombre': 'Piso 1'},
        {'id': 'p2', 'nombre': 'Piso 2'},
      ],
      'espacios': [
        {
          'id': 'lab',
          'nombre': 'Laboratorio de Sistemas',
          'tipo': 'laboratorio',
          'pisos': ['p1'],
          'salones': [
            {'id': 's101', 'nombre': '101'},
            {'id': 's102', 'nombre': '102'},
          ],
        },
        {
          'id': 'aud',
          'nombre': 'Auditorio',
          'tipo': 'auditorio',
          'pisos': ['p1'],
        },
      ],
    });

class _RepositorioFalso implements ZonaRepository {
  _RepositorioFalso(this.zonas, {this.fallosIniciales = 0});

  final List<Zona> zonas;
  int fallosIniciales;
  int llamadas = 0;

  @override
  Future<List<Zona>> obtenerPuntos() async {
    llamadas++;
    if (fallosIniciales > 0) {
      fallosIniciales--;
      throw Exception('asset no disponible');
    }
    return zonas;
  }
}

class _AnalyticsFalso implements AnalyticsAdapter {
  _AnalyticsFalso({this.falla = false});

  final bool falla;
  final eventos = <EventoAnalitica>[];

  @override
  Future<void> registrarEvento(EventoAnalitica evento) async {
    eventos.add(evento);
    if (falla) throw AnalyticsException(500);
  }
}

class _StaticMapFalso implements StaticMapAdapter {
  _StaticMapFalso({this.falla = false});

  final bool falla;

  @override
  Future<ImagenMapa> obtenerImagenMapa({
    required double lat,
    required double lng,
    int zoom = 16,
    int ancho = 400,
    int alto = 300,
  }) async {
    if (falla) throw StaticMapException(403, 'text/html');
    return ImagenMapa(bytesPng: _png1x1, ancho: ancho, alto: alto);
  }
}

Future<void> _montar(
  WidgetTester tester, {
  required ZonaRepository repository,
  AnalyticsAdapter analytics = const AnalyticsAdapterNulo(),
  StaticMapAdapter? staticMap,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ZonasScreen(
        repository: repository,
        analytics: analytics,
        staticMap: staticMap,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Zona', () {
    test('fromJson arma pisos, espacios y salones', () {
      final zona = _zonaDePrueba();

      expect(zona.pisos.map((p) => p.nombre), ['Piso 1', 'Piso 2']);
      expect(zona.espacios, hasLength(2));
      expect(zona.espacios.first.salones.map((s) => s.nombre), ['101', '102']);
      expect(zona.espacios.last.salones, isEmpty);
    });

    test('espaciosEnPiso filtra por piso', () {
      final zona = _zonaDePrueba();

      expect(zona.espaciosEnPiso('p1'), hasLength(2));
      expect(zona.espaciosEnPiso('p2'), isEmpty);
    });

    test('tieneCoordenadas es false solo para el relleno (0,0)', () {
      expect(_zonaDePrueba().tieneCoordenadas, isFalse);
      expect(_zonaDePrueba(lat: 10.4, lng: -75.5).tieneCoordenadas, isTrue);
    });
  });

  group('ZonaRepositoryLocal', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('carga las zonas empaquetadas en assets/data/zonas.json', () async {
      final zonas = await ZonaRepositoryLocal().obtenerPuntos();

      expect(zonas, isNotEmpty);
      expect(zonas.map((z) => z.id).toSet(), hasLength(zonas.length),
          reason: 'los ids de zona deben ser únicos');
    });
  });

  group('ZonasScreen', () {
    testWidgets('lista las zonas y abre el detalle registrando consulta_zona',
        (tester) async {
      final analytics = _AnalyticsFalso();
      await _montar(
        tester,
        repository: _RepositorioFalso([_zonaDePrueba()]),
        analytics: analytics,
      );

      expect(find.text('Edificio A1'), findsOneWidget);

      await tester.tap(find.text('Edificio A1'));
      await tester.pumpAndSettle();

      expect(analytics.eventos.single.nombre, 'consulta_zona');
      expect(analytics.eventos.single.parametros['zona_id'], 'a1');

      await tester.tap(find.text('Piso 1'));
      await tester.pumpAndSettle();
      expect(find.text('Laboratorio de Sistemas'), findsOneWidget);
      expect(find.text('laboratorio — Salones: 101, 102'), findsOneWidget);
      expect(find.text('auditorio'), findsOneWidget);

      await tester.tap(find.text('Piso 2'));
      await tester.pumpAndSettle();
      expect(find.text('Sin espacios registrados en este piso.'), findsOneWidget);
    });

    testWidgets('un error de analítica no impide abrir el detalle (Escenario 3)',
        (tester) async {
      await _montar(
        tester,
        repository: _RepositorioFalso([_zonaDePrueba()]),
        analytics: _AnalyticsFalso(falla: true),
      );

      await tester.tap(find.text('Edificio A1'));
      await tester.pumpAndSettle();

      expect(find.text('Piso 1'), findsOneWidget);
    });

    testWidgets('si falla la carga muestra error y permite reintentar',
        (tester) async {
      final repo = _RepositorioFalso([_zonaDePrueba()], fallosIniciales: 1);
      await _montar(tester, repository: repo);

      expect(find.text('No se pudieron cargar las zonas.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(repo.llamadas, 2);
      expect(find.text('Edificio A1'), findsOneWidget);
    });

    testWidgets('no vuelve a cargar las zonas en cada rebuild', (tester) async {
      final repo = _RepositorioFalso([_zonaDePrueba()]);
      await _montar(tester, repository: repo);
      await _montar(tester, repository: repo);

      expect(repo.llamadas, 1);
    });
  });

  group('ZonaDetalleScreen', () {
    Future<void> abrirDetalle(
      WidgetTester tester,
      Zona zona, {
      StaticMapAdapter? staticMap,
    }) async {
      await _montar(
        tester,
        repository: _RepositorioFalso([zona]),
        staticMap: staticMap,
      );
      await tester.tap(find.text(zona.nombre));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra la miniatura cuando hay adapter y coordenadas',
        (tester) async {
      await abrirDetalle(
        tester,
        _zonaDePrueba(lat: 10.4, lng: -75.5),
        staticMap: _StaticMapFalso(),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('muestra un mensaje controlado si falla Static Maps',
        (tester) async {
      await abrirDetalle(
        tester,
        _zonaDePrueba(lat: 10.4, lng: -75.5),
        staticMap: _StaticMapFalso(falla: true),
      );

      expect(find.text('Mapa no disponible.'), findsOneWidget);
    });

    testWidgets('no pide miniatura para zonas sin coordenadas', (tester) async {
      await abrirDetalle(tester, _zonaDePrueba(), staticMap: _StaticMapFalso());

      expect(find.byType(Image), findsNothing);
      expect(find.text('Mapa no disponible.'), findsNothing);
    });

    testWidgets('avisa cuando la zona no tiene pisos', (tester) async {
      final sinPisos = Zona(
        id: 'cafe',
        nombre: 'Cafetería',
        tipo: 'cafeteria',
        lat: 0,
        lng: 0,
      );
      await abrirDetalle(tester, sinPisos);

      expect(find.text('Esta zona no tiene pisos registrados.'), findsOneWidget);
    });
  });
}
