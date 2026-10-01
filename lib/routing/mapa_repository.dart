import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/log.dart';
import 'grafo.dart';

/// Dueño único del grafo peatonal (arc42 §8, tabla módulo → datos; patrón
/// Repository, ADR 0002). Nadie más lee assets/data/grafo.json.
abstract class MapaRepository {
  Future<GrafoPeatonal> obtenerGrafo();
}

class MapaRepositoryLocal implements MapaRepository {
  GrafoPeatonal? _grafo;

  @override
  Future<GrafoPeatonal> obtenerGrafo() async {
    final enCache = _grafo;
    if (enCache != null) return enCache;
    final reloj = Stopwatch()..start();
    final raw = await rootBundle.loadString('assets/data/grafo.json');
    final grafo = GrafoPeatonal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    Log.info('grafo_cargado', {
      'nodos': grafo.nodos.length,
      'tramos': grafo.tramos.length,
      'duracion_ms': reloj.elapsedMilliseconds,
    });
    return _grafo = grafo;
  }
}
