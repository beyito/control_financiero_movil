import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final String _accessKey = 'access_token';
  final String _refreshKey = 'refresh_token';

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${Config.apiUrl}login/'); // Tu endpoint TokenObtainPairView
    
    try {
      final response = await http.post(
        url,
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _accessKey, value: data['access']);
        await _storage.write(key: _refreshKey, value: data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) return false;

    final url = Uri.parse('${Config.apiUrl}token/refresh/'); // Tu endpoint TokenRefreshView
    
    try {
      final response = await http.post(
        url,
        body: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _accessKey, value: data['access']);
        if (data.containsKey('refresh')) {
          await _storage.write(key: _refreshKey, value: data['refresh']);
        }
        return true;
      }
      await logout();
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<bool> isLoggedIn() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    return refreshToken != null; 
  }

  // Método para registrar un nuevo usuario
  Future<bool> registrarUsuario(Map<String, dynamic> datos) async {
    // Apunta al nuevo endpoint de registro. ¡Ajusta la URL si es distinta!
    final url = Uri.parse('${Config.apiUrl}api/usuario/'); 
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );

      // 201 Created significa que se guardó correctamente en Django
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error en registro: ${response.body}');
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Obtener los datos del perfil del usuario
  Future<Map<String, dynamic>?> getPerfil() async {
    // Asegúrate de que la URL coincida con la que pusiste en urls.py de Django
    final url = Uri.parse('${Config.apiUrl}api/perfil/'); 
    final token = await getAccessToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Actualizar el perfil del usuario (PATCH)
  Future<bool> actualizarPerfil(Map<String, dynamic> datos) async {
    final url = Uri.parse('${Config.apiUrl}api/perfil/'); // Tu endpoint
    final token = await getAccessToken();

    if (token == null) return false;

    try {
      // Usamos PATCH para actualizar solo los campos que enviamos
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(datos),
      );

      // 200 OK significa que se actualizó correctamente
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al actualizar: ${response.body}');
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}