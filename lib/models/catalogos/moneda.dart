// lib/models/catalogos.dart
class Moneda {
  final int idMoneda;
  final String nombre;
  final String simbolo;

  Moneda({required this.idMoneda, required this.nombre, required this.simbolo});

  factory Moneda.fromJson(Map<String, dynamic> json) {
    return Moneda(
      idMoneda: json['id_moneda'],
      nombre: json['nombre'],
      simbolo: json['simbolo'],
    );
  }
}






