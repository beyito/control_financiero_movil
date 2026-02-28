class MetodoPago {
  final int idMetodoPago;
  final String nombre;
  final String? descripcion;

  MetodoPago({required this.idMetodoPago, required this.nombre, this.descripcion});

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      idMetodoPago: json['id_metodo_pago'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}