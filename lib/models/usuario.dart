// lib/models/usuario.dart
class Usuario {
  final int id;
  final String username;
  final DateTime? fechaNacimiento;

  Usuario({
    required this.id,
    required this.username,
    this.fechaNacimiento,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      username: json['username'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] != null 
          ? DateTime.parse(json['fecha_nacimiento']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
    };
  }
}

