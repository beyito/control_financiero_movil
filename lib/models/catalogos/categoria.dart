class Categoria {
  final int idCategoria;
  final String nombre;
  final String? descripcion;
  final int? usuarioId;

  Categoria({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
    this.usuarioId,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id_categoria'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      usuarioId: json['usuario'],
    );
  }
}