class Piso {
  final String id;
  final String nombre; // "Piso 1", "Planta baja"

  Piso({required this.id, required this.nombre});

  factory Piso.fromJson(Map<String, dynamic> json) => Piso(
        id: json['id'],
        nombre: json['nombre'],
      );
}
