import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../core/log.dart';
import 'grafo.dart';

/// Dueño único del grafo peatonal (arc42 §8, tabla módulo → datos; patrón
/// Repository, ADR 0002). Nadie más lee assets/data/grafo.json.
abstract class MapaRepository {
  Future<GrafoPeatonal> obtenerGrafo();
}

class MapaRepositoryLocal implements MapaRepository {
  MapaRepositoryLocal({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _ruta = 'assets/data/grafo.json';

  final AssetBundle _bundle;

  /// Instantánea del grafo para toda la sesión: la app nunca lo escribe, así
  /// que solo cambia con un despliegue nuevo y se invalida al recargar la
  /// página o reiniciar la app (arc42 §8, caché; ADR 0018).
  GrafoPeatonal? _grafo;

  @override
  Future<GrafoPeatonal> obtenerGrafo() async {
    final enCache = _grafo;
    if (enCache != null) return enCache;
    final reloj = Stopwatch()..start();
    final raw = await _leer();
    final grafo = GrafoPeatonal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    Log.info('grafo_cargado', {
      'nodos': grafo.nodos.length,
      'tramos': grafo.tramos.length,
      'duracion_ms': reloj.elapsedMilliseconds,
    });
    return _grafo = grafo;
  }

  Future<String> _leer() async {
    try {
      return await _bundle.loadString(_ruta);
    } catch (_) {
      // El bundle guarda también la lectura fallida: sin esto, en web,
      // «Reintentar» repetiría el mismo error hasta recargar la página.
      _bundle.evict(_ruta);
      rethrow;
    }
  }
}
