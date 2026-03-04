import 'dart:convert';
import 'api_service.dart'; // Importamos tu manejador de peticiones

class IAService {
  // Instanciamos tu ApiService para mantener la sesión y seguridad
  final ApiService _api = ApiService();

  // Método para procesar el texto con Gemini en el backend
  Future<Map<String, dynamic>> procesarDictadoVoz(String textoDictado) async {
    try {
      // IMPORTANTE: Ajusta esta URL a la ruta exacta que pusiste en tu urls.py de Django.
      // Si tu app de Django se llama 'ia', probablemente sea algo así:
      final response = await _api.post('ia/transaccion/', {
        'texto': textoDictado
      });

      // Django REST Framework devuelve 201 cuando crea registros con éxito
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'exito': true,
          'mensaje': data['mensaje'],
          'datos': data['datos'] // Aquí viene el array de transacciones generadas
        };
      } else {
        // Si el backend devuelve un error (ej. texto vacío o fallo en la IA)
        final errorData = jsonDecode(response.body);
        return {
          'exito': false,
          'mensaje': errorData['error'] ?? 'Error desconocido en el servidor de IA'
        };
      }
    } catch (e) {
      // Si falla la conexión a internet o Render está caído
      return {
        'exito': false,
        'mensaje': 'Error de conexión. Revisa tu internet: $e'
      };
    }
  }
}