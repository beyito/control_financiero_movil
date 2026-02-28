class Transaccion {
  final int idTransaccion;
  final int usuarioId;
  final int? movimientoCuentaId; 
  final int? personaId;          
  final int subcategoriaId;
  final String? subcategoriaNombre; 
  final int tipoTransaccionId;
  final String? tipoTransaccionNombre; // <--- 1. Nuevo campo
  final int metodoPagoId;
  final int monedaId;
  final DateTime? fechaRegistro;
  final double monto;

  Transaccion({
    required this.idTransaccion,
    required this.usuarioId,
    this.movimientoCuentaId,
    this.personaId,
    required this.subcategoriaId,
    this.subcategoriaNombre,
    required this.tipoTransaccionId,
    this.tipoTransaccionNombre,        // <--- 2. Al constructor
    required this.metodoPagoId,
    required this.monedaId,
    this.fechaRegistro,
    required this.monto,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) {
    return Transaccion(
      idTransaccion: json['id_transaccion'],
      usuarioId: json['usuario'],
      movimientoCuentaId: json['movimiento_cuenta'],
      personaId: json['persona'],
      subcategoriaId: json['subcategoria'],
      subcategoriaNombre: json['subcategoria_nombre'],
      tipoTransaccionId: json['tipo_transaccion'],
      tipoTransaccionNombre: json['tipo_transaccion_nombre'], // <--- 3. Leer del JSON
      metodoPagoId: json['metodo_pago'],
      monedaId: json['moneda'],
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro']) 
          : null,
      monto: double.tryParse(json['monto'].toString()) ?? 0.0,
    );
  }
}