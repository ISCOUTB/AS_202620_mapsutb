import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../core/log.dart';
import '../models/zona.dart';

abstract class ZonaRepository {
  Future<List<Zona>> obtenerPuntos();
}

class ZonaRepositoryLocal implements ZonaRepository {
  ZonaRepositoryLocal({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _ruta = 'assets/data/zonas.json';

  /// `rootBundle` guarda en memoria la lectura de cada archivo durante toda
  /// la sesión (arc42 §8, caché). Sustituible en pruebas.
  final AssetBundle _bundle;

  @override
  Future<List<Zona>> obtenerPuntos() async {
    final reloj = Stopwatch()..start();
    try {
      final raw = await _bundle.loadString(_ruta);
      final List<dynamic> data = jsonDecode(raw);
      final zonas = data.map((e) => Zona.fromJson(e)).toList();
      Log.info('zonas_cargadas', {
        'cantidad': zonas.length,
        'duracion_ms': reloj.elapsedMilliseconds,
      });
      return zonas;
    } catch (e) {
      // El bundle guarda también la lectura fallida: sin esto, en web,
      // «Reintentar» repetiría el mismo error hasta recargar la página.
      _bundle.evict(_ruta);
      Log.error('zonas_error', {'error': e, 'duracion_ms': reloj.elapsedMilliseconds});
      rethrow;
    }
  }
}
