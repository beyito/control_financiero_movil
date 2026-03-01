class SubCategoria {
  final int idSubcategoria;
  final String nombre;
  final int categoriaId;
  final String? descripcion;
  final int? usuarioId;

  SubCategoria({
    required this.idSubcategoria,
    required this.nombre,
    required this.categoriaId,
    this.descripcion,
    this.usuarioId,
  });

  factory SubCategoria.fromJson(Map<String, dynamic> json) {
    return SubCategoria(
      idSubcategoria: json['id_subcategoria'],
      nombre: json['nombre'],
      categoriaId: json['categoria'],
      descripcion: json['descripcion'],
      usuarioId: json['usuario'],
    );
  }
}