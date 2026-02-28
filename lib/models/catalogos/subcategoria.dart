class SubCategoria {
  final int idSubcategoria;
  final String nombre;
  final String? descripcion;
  final int? usuarioId;

  SubCategoria({
    required this.idSubcategoria,
    required this.nombre,
    this.descripcion,
    this.usuarioId,
  });

  factory SubCategoria.fromJson(Map<String, dynamic> json) {
    return SubCategoria(
      idSubcategoria: json['id_subcategoria'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      usuarioId: json['usuario'],
    );
  }
}