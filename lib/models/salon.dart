class Salon {
  final String id;
  final String nombre;

  /// Ruta de un asset ("assets/salones/a1-401.jpg") o URL ("https://...").
  /// Si es null, se busca el asset por convención: assets/salones/<id>.jpg
  final String? imagen;
  final String? descripcion;

  const Salon({
    required this.id,
    required this.nombre,
    this.imagen,
    this.descripcion,
  });

  factory Salon.fromJson(Map<String, dynamic> json) => Salon(
        id: json['id'],
        nombre: json['nombre'],
        imagen: json['imagen'] as String?,
        descripcion: json['descripcion'] as String?,
      );

  /// Imagen a mostrar: la del JSON o la que sigue la convención del id.
  String get rutaImagen => imagen ?? 'assets/salones/$id.jpg';
}