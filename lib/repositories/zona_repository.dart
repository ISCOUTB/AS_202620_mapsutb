import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/zona.dart';

abstract class ZonaRepository {
  Future<List<Zona>> obtenerPuntos();
}

class ZonaRepositoryLocal implements ZonaRepository {
  @override
  Future<List<Zona>> obtenerPuntos() async {
    final raw = await rootBundle.loadString('assets/data/zonas.json');
    final List<dynamic> data = jsonDecode(raw);
    return data.map((e) => Zona.fromJson(e)).toList();
  }
}
