import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/mapa_widget.dart';
import 'package:mapsutb/core/log.dart';
import 'package:mapsutb/features/mapas_ruteo/presentation/screens/mapa_screen.dart';
import 'package:mapsutb/features/zonas/presentation/screens/zona_detalle_screen.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import 'package:mapsutb/routing/grafo.dart';
import 'package:mapsutb/routing/mapa_repository.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

/// Pantalla de mapa (ADR 0012) con el ruteo (ADR 0013), sin teselas de red.
///
/// Grafo: P ──100── Q ──20 (escalera)── R, y Q ──60── S ──60── R.
/// La zona "a1" entra por R y la zona "a2" por P.
GrafoPeatonal _grafo() {
  const p = NodoGrafo(id: 'P', lat: 10.3690, lng: -75.4660);
  const q = NodoGrafo(id: 'Q', lat: 10.3699, lng: -75.4660);
  const r = NodoGrafo(id: 'R', lat: 10.3701, lng: -75.4660);
  const s = NodoGrafo(id: 'S', lat: 10.3700, lng: -75.4655);
  TramoGrafo t(NodoGrafo a, NodoGrafo b, double m, {bool escaleras = false}) => TramoGrafo(
        desde: a.id, hasta: b.id, metros: m, escaleras: escaleras,
        geometria: [[a.lat, a.lng], [b.lat, b.lng]]);
  return GrafoPeatonal(
    nodos: {for (final n in [p, q, r, s]) n.id: n},
    tramos: [t(p, q, 100), t(q, r, 20, escaleras: true), t(q, s, 60), t(s, r, 60)],
    entradas: {'a1': 'R', 'a2': 'P'},
  );
}

class _ZonasFalsas implements ZonaRepository {
  @override
  Future<List<Zona>> obtenerPuntos() async => [
        Zona(id: 'a1', nombre: 'A1', tipo: 'edificio', lat: 10.3701, lng: -75.4660),
        Zona(id: 'a2', nombre: 'A2', tipo: 'edificio', lat: 10.3690, lng: -75.4660),
        Zona(id: 'contenedores', nombre: 'Contenedores', tipo: 'servicio', lat: 0, lng: 0),
      ];
}

class _MapaFalso implements MapaRepository {
  _MapaFalso({this.falla = false});
  bool falla;
  @override
  Future<GrafoPeatonal> obtenerGrafo() async {
    if (falla) throw Exception('sin grafo');
    return _grafo();
  }
}

class _UbicacionFalsa implements UbicacionService {
  final controller = StreamController<Ubicacion>.broadcast();
  @override
  Stream<Ubicacion> get ubicacionStream => controller.stream;
  @override
  void dispose() => controller.close();
}

class _AnalyticsFalso implements AnalyticsAdapter {
  final eventos = <EventoAnalitica>[];
  @override
  Future<void> registrarEvento(EventoAnalitica evento) async => eventos.add(evento);
}

Future<_UbicacionFalsa> _montar(WidgetTester tester,
    {String? destino, MapaRepository? mapa, AnalyticsAdapter analytics = const AnalyticsAdapterNulo()}) async {
  final ubicacion = _UbicacionFalsa();
  addTearDown(ubicacion.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: MapaScreen(
        zonaRepository: _ZonasFalsas(),
        mapaRepository: mapa ?? _MapaFalso(),
        ubicacionService: ubicacion,
        destinoInicial: destino,
        analytics: analytics,
        mostrarTeselas: false,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return ubicacion;
}

String _resumen(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('resumen_ruta'))).data!;

void main() {
  late List<String> logs;
  setUp(() {
    logs = [];
    Log.salida = logs.add;
  });
  tearDown(() => Log.salida = debugPrint);

  List<Map<String, dynamic>> eventos(String nombre) => [
        for (final l in logs)
          if ((jsonDecode(l) as Map<String, dynamic>)['evento'] == nombre)
            jsonDecode(l) as Map<String, dynamic>,
      ];

  testWidgets('sin destino pide elegir uno y muestra solo zonas con coordenadas', (tester) async {
    await _montar(tester);
    expect(_resumen(tester), contains('Elige un destino'));
    expect(find.byKey(const Key('pin_a1')), findsOneWidget);
    expect(find.byKey(const Key('pin_a2')), findsOneWidget);
    expect(find.byKey(const Key('pin_contenedores')), findsNothing); // sin coordenadas
    expect(find.byTooltip('A1'), findsOneWidget); // nombre al pasar el cursor
  });

  testWidgets('con destino espera la ubicación y luego muestra la ruta', (tester) async {
    final ubicacion = await _montar(tester, destino: 'a1');
    expect(_resumen(tester), contains('Esperando tu ubicación'));

    ubicacion.controller.add(Ubicacion(lat: 10.36901, lng: -75.46601, timestamp: DateTime(2026)));
    await tester.pumpAndSettle();
    // P → Q → R: 120 m con un tramo de escaleras; 120 / 1,2 = 100 s → 2 min
    expect(_resumen(tester), '2 min · 120 m · 1 tramo con escaleras');
    expect(find.byKey(const Key('posicion_usuario')), findsOneWidget);
  });

  testWidgets('evitar escaleras recalcula por el camino sin escaleras', (tester) async {
    final ubicacion = await _montar(tester, destino: 'a1');
    ubicacion.controller.add(Ubicacion(lat: 10.36901, lng: -75.46601, timestamp: DateTime(2026)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('evitar_escaleras')));
    await tester.pumpAndSettle();
    // P → Q → S → R: 220 m → 184 s → 4 min
    expect(_resumen(tester), '4 min · 220 m · sin escaleras');
  });

  testWidgets('tocar una zona en el mapa la elige como destino y registra la solicitud', (tester) async {
    final analytics = _AnalyticsFalso();
    final ubicacion = await _montar(tester, analytics: analytics);
    ubicacion.controller.add(Ubicacion(lat: 10.37008, lng: -75.46600, timestamp: DateTime(2026)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pin_a2')));
    await tester.pumpAndSettle();
    expect(_resumen(tester), contains('m ·'));
    expect(find.byTooltip('A2'), findsNothing); // el elegido muestra su etiqueta, sin tooltip
    expect(analytics.eventos.single.nombre, 'solicitud_ruta');
    expect(analytics.eventos.single.parametros['zona_destino'], 'a2');
  });

  testWidgets('fuera del campus lo avisa en lugar de trazar una ruta absurda', (tester) async {
    final ubicacion = await _montar(tester, destino: 'a1');
    ubicacion.controller.add(Ubicacion(lat: 10.4254, lng: -75.5077, timestamp: DateTime(2026))); // sede Manga
    await tester.pumpAndSettle();
    expect(_resumen(tester), contains('fuera del campus'));
  });

  testWidgets('si no carga el grafo muestra error y permite reintentar', (tester) async {
    final mapa = _MapaFalso(falla: true);
    await _montar(tester, mapa: mapa);
    expect(find.text('No se pudo cargar el mapa del campus.'), findsOneWidget);

    mapa.falla = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(_resumen(tester), contains('Elige un destino'));
  });

  testWidgets('"Cómo llegar" en el detalle de zona cierra el detalle y pide la ruta', (tester) async {
    String? pedido;
    final zona = Zona(id: 'a1', nombre: 'A1', tipo: 'edificio', lat: 10.3701, lng: -75.4660);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ZonaDetalleScreen(zona: zona, onComoLlegar: (id) => pedido = id),
          )),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();
    expect(pedido, 'a1');
    expect(find.text('Cómo llegar'), findsNothing); // el detalle se cerró
  });

  testWidgets('sin coordenadas el detalle no ofrece "Cómo llegar"', (tester) async {
    final zona = Zona(id: 'contenedores', nombre: 'Contenedores', tipo: 'servicio', lat: 0, lng: 0);
    await tester.pumpWidget(MaterialApp(home: ZonaDetalleScreen(zona: zona, onComoLlegar: (_) {})));
    expect(find.text('Cómo llegar'), findsNothing);
  });

  testWidgets('mide la parte de pantalla del Escenario 2 una vez por destino', (tester) async {
    final ubicacion = await _montar(tester, destino: 'a1');
    ubicacion.controller.add(Ubicacion(lat: 10.36901, lng: -75.46601, timestamp: DateTime(2026)));
    await tester.pumpAndSettle();

    final medidas = eventos('ruta_mostrada');
    expect(medidas, hasLength(1));
    expect(medidas.single['zona_destino'], 'a1');
    expect(medidas.single['metros'], 120);
    expect(medidas.single['duracion_ms'], isA<int>());
    // El umbral del Escenario 2 es 5 s; aquí se comprueba que la medida existe
    // y es razonable en el entorno de pruebas.
    expect(medidas.single['duracion_ms'] as int, lessThan(5000));

    // Nuevas posiciones del GPS no vuelven a medir el mismo destino.
    ubicacion.controller.add(Ubicacion(lat: 10.36902, lng: -75.46602, timestamp: DateTime(2026)));
    await tester.pumpAndSettle();
    expect(eventos('ruta_mostrada'), hasLength(1));

    // Cambiar de destino sí produce una medida nueva. Se usa el desplegable:
    // con la ruta dibujada la cámara se reencuadra y los pines se mueven.
    await tester.tap(find.byKey(const Key('destino')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    expect(eventos('ruta_mostrada'), hasLength(2));
    expect(eventos('ruta_mostrada').last['zona_destino'], 'a2');
  });

  testWidgets('el Adapter del mapa recibe la ruta y el destino elegido', (tester) async {
    // Se prueba el contrato de MapaWidget, no el interior de flutter_map: el
    // aislamiento del Adapter (ADR 0012) exige que esos tipos no salgan de él.
    final ubicacion = await _montar(tester, destino: 'a1');
    MapaWidget mapa() => tester.widget<MapaWidget>(find.byType(MapaWidget));
    expect(mapa().lugarSeleccionado, 'a1');
    expect(mapa().ruta, isEmpty); // todavía sin posición
    expect(mapa().latCentro, closeTo(10.3701, 0.0001)); // centrado en el destino

    ubicacion.controller.add(Ubicacion(lat: 10.36901, lng: -75.46601, timestamp: DateTime(2026)));
    await tester.pumpAndSettle();
    expect(mapa().ruta.first, [10.3690, -75.4660]); // arranca en el nodo P
    expect(mapa().ruta.last, [10.3701, -75.4660]); // termina en la entrada de A1
    expect(mapa().posicion, [10.36901, -75.46601]);

    await tester.tap(find.byKey(const Key('destino')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    expect(mapa().lugarSeleccionado, 'a2');
    expect(mapa().latCentro, closeTo(10.3690, 0.0001)); // la cámara sigue al destino
  });
}
