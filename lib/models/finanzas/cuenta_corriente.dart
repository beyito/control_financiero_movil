class CuentaCorriente {
  final int idCuentaCorriente;
  final int personaId;
  final String? personaNombre; // <--- Nuevo
  final int monedaId;
  final String? monedaSimbolo; // <--- Nuevo
  final DateTime? fechaRegistro;

  CuentaCorriente({
    required this.idCuentaCorriente,
    required this.personaId,
    this.personaNombre,
    required this.monedaId,
    this.monedaSimbolo,
    this.fechaRegistro,
  });

  factory CuentaCorriente.fromJson(Map<String, dynamic> json) {
    return CuentaCorriente(
      idCuentaCorriente: json['id_cuenta_corriente'],
      personaId: json['persona'],
      personaNombre: json['persona_nombre'], // Leemos el nombre
      monedaId: json['moneda'],
      monedaSimbolo: json['moneda_simbolo'], // Leemos el símbolo
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro']) 
          : null,
    );
  }
}




