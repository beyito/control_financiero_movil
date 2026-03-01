class MovimientoCuenta {
  final int idMovimientoCuenta;
  final int cuentaCorrienteId;
  final int tipoMovimientoId;
  final String? tipoMovimientoNombre; // <--- Nuevo
  final DateTime? fechaRegistro;
  final double montoInicial;
  final double saldoPendiente;
  final String? concepto; // <--- Nuevo

  MovimientoCuenta({
    required this.idMovimientoCuenta,
    required this.cuentaCorrienteId,
    required this.tipoMovimientoId,
    this.tipoMovimientoNombre,
    this.fechaRegistro,
    required this.montoInicial,
    required this.saldoPendiente,
    this.concepto,
  });

  factory MovimientoCuenta.fromJson(Map<String, dynamic> json) {
    return MovimientoCuenta(
      idMovimientoCuenta: json['id_movimiento_cuenta'],
      cuentaCorrienteId: json['cuenta_corriente'],
      tipoMovimientoId: json['tipo_movimiento'],
      tipoMovimientoNombre: json['tipo_movimiento_nombre'], // Leemos el nombre
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro']) 
          : null,
      montoInicial: double.tryParse(json['monto_inicial'].toString()) ?? 0.0,
      saldoPendiente: double.tryParse(json['saldo_pendiente'].toString()) ?? 0.0,
      concepto: json['concepto'],
    );
  }
}