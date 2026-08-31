class Salon {
  final String id;
  final String nombre; // "301", "302"

  Salon({required this.id, required this.nombre});

  factory Salon.fromJson(Map<String, dynamic> json) => Salon(
        id: json['id'],
        nombre: json['nombre'],
      );
}
