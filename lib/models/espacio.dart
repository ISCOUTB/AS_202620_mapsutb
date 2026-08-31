import 'salon.dart';

class Espacio {
  final String id;
  final String nombre; // "Laboratorios de Sistemas"
  final String tipo; // 'salon', 'laboratorio', 'oficina', 'auditorio', ...
  final List<String> pisos; // ids de los pisos que abarca este espacio
  final List<Salon> salones; // salones individuales dentro de este espacio (si aplica)

  Espacio({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.pisos,
    this.salones = const [],
  });

  factory Espacio.fromJson(Map<String, dynamic> json) => Espacio(
        id: json['id'],
        nombre: json['nombre'],
        tipo: json['tipo'],
        pisos: List<String>.from(json['pisos'] ?? []),
        salones: (json['salones'] as List<dynamic>? ?? [])
            .map((e) => Salon.fromJson(e))
            .toList(),
      );
}
