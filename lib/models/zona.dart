import 'piso.dart';
import 'espacio.dart';

class Zona {
  final String id;
  final String nombre;
  final String tipo; // 'edificio', 'cafeteria', 'parqueadero', 'oficina_institucional', 'zona_comun'
  final double lat;
  final double lng;
  final List<Piso> pisos;
  final List<Espacio> espacios;

  Zona({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.lat,
    required this.lng,
    this.pisos = const [],
    this.espacios = const [],
  });

  factory Zona.fromJson(Map<String, dynamic> json) => Zona(
        id: json['id'],
        nombre: json['nombre'],
        tipo: json['tipo'],
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        pisos: (json['pisos'] as List<dynamic>? ?? [])
            .map((e) => Piso.fromJson(e))
            .toList(),
        espacios: (json['espacios'] as List<dynamic>? ?? [])
            .map((e) => Espacio.fromJson(e))
            .toList(),
      );

  /// Espacios que ocupan un piso específico (un espacio puede aparecer
  /// en más de un piso, ej. un auditorio de doble altura).
  List<Espacio> espaciosEnPiso(String pisoId) =>
      espacios.where((e) => e.pisos.contains(pisoId)).toList();
}
