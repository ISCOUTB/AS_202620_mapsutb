import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../core/log.dart';
import '../models/zona.dart';

abstract class ZonaRepository {
  Future<List<Zona>> obtenerPuntos();
}

class ZonaRepositoryLocal implements ZonaRepository {
  @override
  Future<List<Zona>> obtenerPuntos() async {
    final reloj = Stopwatch()..start();
    try {
      final raw = await rootBundle.loadString('assets/data/zonas.json');
      final List<dynamic> data = jsonDecode(raw);
      final zonas = data.map((e) => Zona.fromJson(e)).toList();
      Log.info('zonas_cargadas', {
        'cantidad': zonas.length,
        'duracion_ms': reloj.elapsedMilliseconds,
      });
      return zonas;
    } catch (e) {
      Log.error('zonas_error', {'error': e, 'duracion_ms': reloj.elapsedMilliseconds});
      rethrow;
    }
  }
}
