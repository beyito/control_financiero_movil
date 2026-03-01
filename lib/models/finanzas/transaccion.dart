class Transaccion {
  final int idTransaccion;
  final double monto;
  final String? concepto;
  final DateTime? fechaRegistro;
  final int? subcategoriaId;
  final int? monedaId;
  final int? tipoTransaccionId;
  final int? metodoPagoId;
  final int? personaId;
  final int? movimientoCuentaId;

  // Los campos extra que nos manda Django
  final String? subcategoriaNombre;
  final String? tipoTransaccionNombre;
  
  // --- AÑADE ESTOS 3 NUEVOS CAMPOS ---
  final String? categoriaPadreNombre;
  final String? metodoPagoNombre;
  final String? personaNombre;

  Transaccion({
    required this.idTransaccion,
    required this.monto,
    this.concepto,
    this.fechaRegistro,
    this.subcategoriaId,
    this.monedaId,
    this.tipoTransaccionId,
    this.metodoPagoId,
    this.personaId,
    this.movimientoCuentaId,
    this.subcategoriaNombre,
    this.tipoTransaccionNombre,
    
    // --- NO OLVIDES PONERLOS AQUÍ ---
    this.categoriaPadreNombre,
    this.metodoPagoNombre,
    this.personaNombre,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) {
    return Transaccion(
      idTransaccion: json['id_transaccion'],
      monto: double.parse(json['monto'].toString()),
      concepto: json['concepto'],
      fechaRegistro: json['fecha_registro'] != null ? DateTime.parse(json['fecha_registro']) : null,
      subcategoriaId: json['subcategoria'],
      monedaId: json['moneda'],
      tipoTransaccionId: json['tipo_transaccion'],
      metodoPagoId: json['metodo_pago'],
      personaId: json['persona'],
      movimientoCuentaId: json['movimiento_cuenta'],
      subcategoriaNombre: json['subcategoria_nombre'],
      tipoTransaccionNombre: json['tipo_transaccion_nombre'],
      
      // --- Y LEERLOS DEL JSON ---
      categoriaPadreNombre: json['categoria_padre_nombre'],
      metodoPagoNombre: json['metodo_pago_nombre'],
      personaNombre: json['persona_nombre'],
    );
  }
}