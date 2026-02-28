// lib/models/persona.dart
class Persona {
  final int idPersona;
  final int usuarioId; // Relación con Usuario (ForeignKey)
  final String nombre;
  final DateTime? fechaRegistro;
  final String? descripcion;

  Persona({
    required this.idPersona,
    required this.usuarioId,
    required this.nombre,
    this.fechaRegistro,
    this.descripcion,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      idPersona: json['id_persona'],
      usuarioId: json['usuario'] is int ? json['usuario'] : json['usuario']['id'], 
      nombre: json['nombre'],
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro']) 
          : null,
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_persona': idPersona,
      'usuario': usuarioId,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}