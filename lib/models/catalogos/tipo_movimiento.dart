class TipoMovimiento {
  final int idTipoMovimiento;
  final String nombre;
  final String? descripcion;

  TipoMovimiento({required this.idTipoMovimiento, required this.nombre, this.descripcion});

  factory TipoMovimiento.fromJson(Map<String, dynamic> json) {
    return TipoMovimiento(
      idTipoMovimiento: json['id_tipo_movimiento'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}