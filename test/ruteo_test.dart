import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/routing/grafo.dart';
import 'package:mapsutb/routing/mapa_repository.dart';
import 'package:mapsutb/routing/servicio_ruteo.dart';

/// Pruebas del ruteo interno (ADR 0013, Escenario 2, aspecto A-01).
///
/// Grafo de prueba (metros):
///
///   A ──10── B ──10── C ──5 (escalera)── D
///    \                │                  │
///     └──────50───────┘        B ──30── E ──30── D
///
///   F está suelto (sin tramos).
GrafoPeatonal grafoDePrueba() {
  NodoGrafo n(String id, double lat, double lng) => NodoGrafo(id: id, lat: lat, lng: lng);
  TramoGrafo t(String a, String b, double m, {bool escaleras = false}) =>
      TramoGrafo(desde: a, hasta: b, metros: m, escaleras: escaleras, geometria: [
        [nodos[a]!.lat, nodos[a]!.lng],
        [nodos[b]!.lat, nodos[b]!.lng],
      ]);
  nodos = {
    for (final x in [
      n('A', 10.3690, -75.4660),
      n('B', 10.3691, -75.4660),
      n('C', 10.3692, -75.4660),
      n('D', 10.3693, -75.4660),
      n('E', 10.3692, -75.4655),
      n('F', 10.3700, -75.4650),
    ])
      x.id: x,
  };
  return GrafoPeatonal(
    nodos: nodos,
    tramos: [
      t('A', 'B', 10),
      t('B', 'C', 10),
      t('A', 'C', 50),
      t('C', 'D', 5, escaleras: true),
      t('B', 'E', 30),
      t('E', 'D', 30),
    ],
    entradas: {'zona_a': 'A', 'zona_d': 'D', 'zona_f': 'F'},
  );
}

late Map<String, NodoGrafo> nodos;

/// Implementación DEFECTUOSA a propósito (mutante): busca la ruta con menos
/// tramos (BFS) en lugar de la de menos metros. Sirve para demostrar que la
/// prueba de "ruta más corta" detecta ese defecto.
List<String> rutaMutanteMenosTramos(GrafoPeatonal g, String origen, String destino) {
  final previo = <String, String>{};
  final cola = Queue<String>()..add(origen);
  final visto = {origen};
  while (cola.isNotEmpty) {
    final x = cola.removeFirst();
    if (x == destino) break;
    for (final t in g.tramosDe(x)) {
      final y = t.otroExtremo(x);
      if (visto.add(y)) {
        previo[y] = x;
        cola.add(y);
      }
    }
  }
  final camino = [destino];
  while (camino.last != origen) {
    camino.add(previo[camino.last]!);
  }
  return camino.reversed.toList();
}

double metrosDe(GrafoPeatonal g, List<String> camino) {
  var total = 0.0;
  for (var i = 1; i < camino.length; i++) {
    total += g
        .tramosDe(camino[i - 1])
        .where((t) => t.otroExtremo(camino[i - 1]) == camino[i])
        .map((t) => t.metros)
        .reduce((a, b) => a < b ? a : b);
  }
  return total;
}

void main() {
  group('Dijkstra sobre un grafo conocido', () {
    late ServicioRuteo ruteo;
    late GrafoPeatonal g;
    setUp(() {
      g = grafoDePrueba();
      ruteo = ServicioRuteo(g);
    });

    test('elige la ruta de menos metros, no la de menos tramos', () {
      final r = ruteo.rutaEntreNodos('A', 'C')!;
      expect(r.nodos, ['A', 'B', 'C']);
      expect(r.metros, 20);
    });

    test('prueba de mutación: el algoritmo de menos tramos no pasa la verificación', () {
      // El mutante va directo A→C (1 tramo, 50 m). La verificación de la
      // prueba anterior (20 m) lo rechaza: si alguien reemplaza Dijkstra
      // por una búsqueda por número de tramos, esa prueba falla.
      final mutante = rutaMutanteMenosTramos(g, 'A', 'C');
      expect(mutante, ['A', 'C']);
      expect(metrosDe(g, mutante), isNot(20));
      expect(metrosDe(g, mutante), greaterThan(ruteo.rutaEntreNodos('A', 'C')!.metros));
    });

    test('usa la escalera si es más corta y cuenta los tramos con escalera', () {
      final r = ruteo.rutaEntreNodos('A', 'D')!;
      expect(r.nodos, ['A', 'B', 'C', 'D']);
      expect(r.metros, 25);
      expect(r.tramosConEscaleras, 1);
    });

    test('con evitarEscaleras rodea por el camino sin escaleras', () {
      final r = ruteo.rutaEntreNodos('A', 'D', evitarEscaleras: true)!;
      expect(r.nodos, ['A', 'B', 'E', 'D']);
      expect(r.metros, 70);
      expect(r.tramosConEscaleras, 0);
    });

    test('es simétrica y la geometría va del origen al destino', () {
      final ida = ruteo.rutaEntreNodos('A', 'D')!;
      final vuelta = ruteo.rutaEntreNodos('D', 'A')!;
      expect(vuelta.metros, ida.metros);
      expect(vuelta.geometria.first, [nodos['D']!.lat, nodos['D']!.lng]);
      expect(vuelta.geometria.last, [nodos['A']!.lat, nodos['A']!.lng]);
      expect(ida.geometria, hasLength(4)); // sin puntos repetidos en las uniones
    });

    test('origen igual al destino: ruta de 0 m', () {
      final r = ruteo.rutaEntreNodos('B', 'B')!;
      expect(r.metros, 0);
      expect(r.nodos, ['B']);
      expect(r.tiempoCaminando, Duration.zero);
    });

    test('devuelve null si no hay camino o el nodo no existe', () {
      expect(ruteo.rutaEntreNodos('A', 'F'), isNull);
      expect(ruteo.rutaEntreNodos('A', 'Z'), isNull);
      expect(ruteo.rutaEntreZonas('zona_a', 'zona_f'), isNull);
      expect(ruteo.rutaEntreZonas('zona_a', 'sin_entrada'), isNull);
    });

    test('rutaEntreZonas usa la entrada de cada zona', () {
      final r = ruteo.rutaEntreZonas('zona_a', 'zona_d')!;
      expect(r.nodos.first, 'A');
      expect(r.nodos.last, 'D');
      expect(r.tiempoCaminando.inSeconds, (25 / Ruta.velocidadMetrosPorSegundo).round());
    });

    test('rutaDesdePosicion parte del nodo más cercano a la posición', () {
      final r = ruteo.rutaDesdePosicion(10.36901, -75.46601, 'zona_d')!;
      expect(r.nodos.first, 'A');
      expect(ruteo.rutaDesdePosicion(10.369, -75.466, 'sin_entrada'), isNull);
    });
  });

  group('Grafo real del campus (assets/data/grafo.json)', () {
    final g = GrafoPeatonal.fromJson(
        jsonDecode(File('assets/data/grafo.json').readAsStringSync()) as Map<String, dynamic>);
    final ruteo = ServicioRuteo(g);
    final zonas = g.entradas.keys.toList()..sort();

    test('hay ruta entre cada par de zonas conectadas, simétrica y no menor que la línea recta', () {
      for (final a in zonas) {
        for (final b in zonas) {
          final r = ruteo.rutaEntreZonas(a, b);
          expect(r, isNotNull, reason: '$a → $b');
          final na = g.nodos[g.entradas[a]]!, nb = g.nodos[g.entradas[b]]!;
          expect(r!.metros, greaterThanOrEqualTo(metrosEntre(na.lat, na.lng, nb.lat, nb.lng) - 0.5));
          expect(r.metros, closeTo(ruteo.rutaEntreZonas(b, a)!.metros, 0.01));
        }
      }
    });

    test('Escenario 2: calcular una ruta tarda mucho menos que el umbral de 5 s', () {
      final tiempos = <int>[];
      for (final a in zonas) {
        for (final b in zonas) {
          final reloj = Stopwatch()..start();
          ruteo.rutaEntreZonas(a, b);
          tiempos.add(reloj.elapsedMicroseconds);
        }
      }
      tiempos.sort();
      final p95 = tiempos[(tiempos.length * 0.95).floor() - 1];
      // ignore: avoid_print
      print('Ruteo en el grafo real: ${tiempos.length} rutas, p95 ${p95 / 1000} ms, máx ${tiempos.last / 1000} ms');
      expect(p95, lessThan(500 * 1000)); // 0,5 s: un 10 % del presupuesto del escenario
    });
  });

  group('MapaRepositoryLocal', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('carga el grafo empaquetado y lo guarda en caché', () async {
      final repo = MapaRepositoryLocal();
      final g1 = await repo.obtenerGrafo();
      final g2 = await repo.obtenerGrafo();
      expect(g1.nodos, isNotEmpty);
      expect(g1.entradas, isNotEmpty);
      expect(identical(g1, g2), isTrue);
    });
  });
}
