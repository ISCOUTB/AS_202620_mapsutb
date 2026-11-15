import 'salon.dart';

class Espacio {
  final String id;
  final String nombre; // "Laboratorios de Sistemas"
  final String tipo; // 'salon', 'laboratorio', 'oficina', 'auditorio', ...
  final List<String> pisos; // ids de los pisos que abarca este espacio
  final List<Salon> salones; // salones individuales dentro de este espacio (si aplica)

  /// Coordenadas propias del espacio. Solo se llenan cuando el espacio
  /// no está en el mismo punto que su zona (ej. las canchas de Espacios
  /// Libres). Si son null, se usan las de la zona (ver `Zona.ubicacionDe`).
  final double? lat;
  final double? lng;

  Espacio({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.pisos,
    this.salones = const [],
    this.lat,
    this.lng,
  });

  factory Espacio.fromJson(Map<String, dynamic> json) => Espacio(
        id: json['id'],
        nombre: json['nombre'],
        tipo: json['tipo'],
        pisos: List<String>.from(json['pisos'] ?? []),
        salones: (json['salones'] as List<dynamic>? ?? [])
            .map((e) => Salon.fromJson(e))
            .toList(),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );

  /// `true` si este espacio tiene un punto propio distinto al de su zona.
  bool get tieneCoordenadasPropias => lat != null && lng != null;
}