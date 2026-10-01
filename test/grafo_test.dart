import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Integridad de assets/data/grafo.json, el grafo peatonal del campus que
/// genera scripts/campo/analizar_campo.py desde OpenStreetMap y el
/// levantamiento de campo (ADR 0011). Si una regeneración rompe el grafo,
/// esta prueba falla antes de que el ruteo lo use.
void main() {
  final grafo = jsonDecode(File('assets/data/grafo.json').readAsStringSync())
      as Map<String, dynamic>;
  final zonas = (jsonDecode(File('assets/data/zonas.json').readAsStringSync())
          as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final nodos = {
    for (final n in (grafo['nodos'] as List).cast<Map<String, dynamic>>())
      n['id'] as String: n,
  };
  final aristas = (grafo['aristas'] as List).cast<Map<String, dynamic>>();
  final entradas = (grafo['entradas'] as List).cast<Map<String, dynamic>>();

  // Límite aproximado del Campus Tecnológico (Ternera).
  bool enCampus(num lat, num lng) =>
      lat > 10.3650 && lat < 10.3725 && lng > -75.4690 && lng < -75.4605;

  double metros(List a, List b) {
    const r = 6371000.0;
    final la1 = (a[0] as num) * pi / 180, la2 = (b[0] as num) * pi / 180;
    final dLng = ((b[1] as num) - (a[1] as num)) * pi / 180;
    final x = dLng * cos((la1 + la2) / 2), y = la2 - la1;
    return r * sqrt(x * x + y * y);
  }

  test('declara la licencia de OpenStreetMap (ODbL)', () {
    expect(grafo['licencia'], contains('ODbL'));
    expect(grafo['licencia'], contains('OpenStreetMap'));
  });

  test('todos los nodos están dentro del campus', () {
    expect(nodos, isNotEmpty);
    for (final n in nodos.values) {
      expect(enCampus(n['lat'] as num, n['lng'] as num), isTrue,
          reason: '${n['id']} fuera del campus');
    }
  });

  test('cada tramo une nodos existentes y su longitud coincide con su geometría',
      () {
    for (final a in aristas) {
      expect(nodos.containsKey(a['desde']), isTrue, reason: '${a['desde']}');
      expect(nodos.containsKey(a['hasta']), isTrue, reason: '${a['hasta']}');
      final geo = (a['geometria'] as List).cast<List>();
      expect(geo.length, greaterThanOrEqualTo(2));
      var largo = 0.0;
      for (var i = 1; i < geo.length; i++) {
        largo += metros(geo[i - 1], geo[i]);
      }
      expect(a['metros'] as num, greaterThan(0));
      expect((a['metros'] as num) - largo, closeTo(0, 1.5),
          reason: 'tramo ${a['desde']}→${a['hasta']}');
      final inicio = nodos[a['desde']]!;
      expect(metros(geo.first, [inicio['lat'], inicio['lng']]), lessThan(0.5));
    }
  });

  test('las entradas apuntan a zonas reales y a nodos del grafo', () {
    final ids = zonas.map((z) => z['id']).toSet();
    for (final e in entradas) {
      expect(ids, contains(e['zona']));
      expect(nodos.containsKey(e['nodo']), isTrue, reason: '${e['zona']}');
    }
  });

  test('las entradas conectadas son alcanzables entre sí (una sola red)', () {
    final vecinos = <String, Set<String>>{};
    for (final a in aristas) {
      vecinos.putIfAbsent(a['desde'] as String, () => {}).add(a['hasta'] as String);
      vecinos.putIfAbsent(a['hasta'] as String, () => {}).add(a['desde'] as String);
    }
    final conectadas =
        entradas.where((e) => e['conectada'] == true).map((e) => e['nodo'] as String).toList();
    expect(conectadas, isNotEmpty);
    final visto = <String>{conectadas.first};
    final cola = Queue<String>()..add(conectadas.first);
    while (cola.isNotEmpty) {
      for (final v in vecinos[cola.removeFirst()] ?? const <String>{}) {
        if (visto.add(v)) cola.add(v);
      }
    }
    for (final n in conectadas) {
      expect(visto, contains(n), reason: 'entrada en $n no alcanzable');
    }
  });

  test('toda zona con coordenadas está dentro del campus y tiene entrada', () {
    final conEntrada = entradas.map((e) => e['zona']).toSet();
    for (final z in zonas) {
      final lat = z['lat'] as num, lng = z['lng'] as num;
      if (lat == 0 && lng == 0) continue; // aún sin levantar
      expect(enCampus(lat, lng), isTrue, reason: '${z['id']}');
      expect(conEntrada, contains(z['id']), reason: '${z['id']} sin entrada');
    }
  });
}
