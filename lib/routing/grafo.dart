import 'dart:math';

/// Modelo del grafo peatonal del campus (contexto Ruteo, ADR 0006 y 0011).
///
/// Se construye desde assets/data/grafo.json, que genera
/// scripts/campo/analizar_campo.py a partir de OpenStreetMap y del
/// levantamiento de campo. Del contexto Catálogo solo conoce el **id** de
/// cada zona (en [GrafoPeatonal.entradas]); nunca el modelo Zona.
class NodoGrafo {
  const NodoGrafo({required this.id, required this.lat, required this.lng});

  final String id;
  final double lat;
  final double lng;
}

class TramoGrafo {
  const TramoGrafo({
    required this.desde,
    required this.hasta,
    required this.metros,
    required this.escaleras,
    required this.geometria,
  });

  final String desde;
  final String hasta;
  final double metros;
  final bool escaleras;

  /// Puntos [lat, lng] del tramo, en el sentido desde → hasta.
  final List<List<double>> geometria;

  String otroExtremo(String nodo) => nodo == desde ? hasta : desde;

  /// Geometría recorrida saliendo de [nodo].
  List<List<double>> geometriaDesde(String nodo) =>
      nodo == desde ? geometria : geometria.reversed.toList();
}

class GrafoPeatonal {
  GrafoPeatonal({
    required this.nodos,
    required this.tramos,
    required this.entradas,
  }) {
    for (final t in tramos) {
      _adyacencia.putIfAbsent(t.desde, () => []).add(t);
      _adyacencia.putIfAbsent(t.hasta, () => []).add(t);
    }
  }

  factory GrafoPeatonal.fromJson(Map<String, dynamic> json) {
    final nodos = <String, NodoGrafo>{
      for (final n in (json['nodos'] as List).cast<Map<String, dynamic>>())
        n['id'] as String: NodoGrafo(
          id: n['id'] as String,
          lat: (n['lat'] as num).toDouble(),
          lng: (n['lng'] as num).toDouble(),
        ),
    };
    final tramos = [
      for (final t in (json['aristas'] as List).cast<Map<String, dynamic>>())
        TramoGrafo(
          desde: t['desde'] as String,
          hasta: t['hasta'] as String,
          metros: (t['metros'] as num).toDouble(),
          escaleras: t['escaleras'] as bool? ?? false,
          geometria: [
            for (final p in (t['geometria'] as List).cast<List>())
              [(p[0] as num).toDouble(), (p[1] as num).toDouble()],
          ],
        ),
    ];
    final entradas = <String, String>{
      for (final e in (json['entradas'] as List).cast<Map<String, dynamic>>())
        e['zona'] as String: e['nodo'] as String,
    };
    return GrafoPeatonal(nodos: nodos, tramos: tramos, entradas: entradas);
  }

  final Map<String, NodoGrafo> nodos;
  final List<TramoGrafo> tramos;

  /// Nodo de llegada de cada zona: id de zona → id de nodo.
  final Map<String, String> entradas;

  final Map<String, List<TramoGrafo>> _adyacencia = {};

  List<TramoGrafo> tramosDe(String nodo) => _adyacencia[nodo] ?? const [];

  /// Nodo más cercano a una posición (p. ej. la del GPS) y su distancia en m.
  (NodoGrafo, double)? nodoMasCercano(double lat, double lng) {
    (NodoGrafo, double)? mejor;
    for (final n in nodos.values) {
      final d = metrosEntre(lat, lng, n.lat, n.lng);
      if (mejor == null || d < mejor.$2) mejor = (n, d);
    }
    return mejor;
  }
}

/// Distancia en metros entre dos coordenadas (aproximación plana local,
/// precisa a escala de campus).
double metrosEntre(double lat1, double lng1, double lat2, double lng2) {
  const radioTierra = 6371000.0;
  final la1 = lat1 * pi / 180, la2 = lat2 * pi / 180;
  final x = (lng2 - lng1) * pi / 180 * cos((la1 + la2) / 2);
  final y = la2 - la1;
  return radioTierra * sqrt(x * x + y * y);
}
