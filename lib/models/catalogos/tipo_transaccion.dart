class TipoTransaccion {
  final int idTipoTransaccion;
  final String nombre;
  final String? descripcion;

  TipoTransaccion({required this.idTipoTransaccion, required this.nombre, this.descripcion});

  factory TipoTransaccion.fromJson(Map<String, dynamic> json) {
    return TipoTransaccion(
      idTipoTransaccion: json['id_tipo_transaccion'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}
