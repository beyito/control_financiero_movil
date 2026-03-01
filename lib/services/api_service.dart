import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Método GET genérico
  Future<http.Response> get(String endpoint) async {
    String? token = await _authService.getAccessToken();
    var url = Uri.parse('${Config.apiUrl}$endpoint');
    
    var response = await http.get(
      url, 
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}
    );

    // Si el token de acceso expiró, intentamos renovarlo
    if (response.statusCode == 401) {
      bool refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Si se renovó con éxito, volvemos a intentar la petición original
        token = await _authService.getAccessToken();
        response = await http.get(
          url, 
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}
        );
      }
    }
    return response;
  }

  // Método POST genérico (para crear gastos, ingresos, etc.)
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    String? token = await _authService.getAccessToken();
    var url = Uri.parse('${Config.apiUrl}$endpoint');
    
    var response = await http.post(
      url, 
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body)
    );

    if (response.statusCode == 401) {
      bool refreshed = await _authService.refreshToken();
      if (refreshed) {
        token = await _authService.getAccessToken();
        response = await http.post(
          url, 
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode(body)
        );
      }
    }
    return response;
  }

  // Método DELETE genérico (para eliminar gastos, ingresos, etc.)
  Future<http.Response> delete(String endpoint) async {
    String? token = await _authService.getAccessToken();
    var url = Uri.parse('${Config.apiUrl}$endpoint');
    
    var response = await http.delete(
      url, 
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}
    );

    if (response.statusCode == 401) {
      bool refreshed = await _authService.refreshToken();
      if (refreshed) {
        token = await _authService.getAccessToken();
        response = await http.delete(
          url, 
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}
        );
      }
    }
   return response;
  }

}