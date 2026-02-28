import 'dart:convert';
import '../models/catalogos/categoria.dart'; // Importamos los modelos que creamos
import '../models/catalogos/metodo_pago.dart'; // Importamos los modelos que creamos
import '../models/catalogos/moneda.dart'; // Importamos los modelos que creamos
import '../models/catalogos/tipo_movimiento.dart'; // Importamos los modelos que creamos
import '../models/catalogos/tipo_transaccion.dart'; // Importamos los modelos que creamos
import '../models/catalogos/subcategoria.dart';
import 'api_service.dart';

class CatalogoService {
  final ApiService _api = ApiService();
// Método para obtener las categorías
  Future<List<Categoria>> getCategorias() async {
    // IMPORTANTE: Ajusta esta URL a la que tengas en tu Django (ej. 'finance/categorias/')
    final response = await _api.get('finance/categoria/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => Categoria.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  // Método para obtener los métodos de pago
  Future<List<MetodoPago>> getMetodosPago() async {
    // IMPORTANTE: Ajusta esta URL a tu Django (ej. 'finance/metodos-pago/')
    final response = await _api.get('finance/metodopago/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => MetodoPago.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar métodos de pago');
    }
  }

  // Método para obtener las monedas
  Future<List<Moneda>> getMonedas() async {
    // IMPORTANTE: Ajusta esta URL a tu Django (ej. 'finance/monedas/')
    final response = await _api.get('finance/moneda/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => Moneda.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar monedas');
    }
  }

  // Método para obtener los tipos de movimiento
  Future<List<TipoMovimiento>> getTiposMovimiento() async { 
    // IMPORTANTE: Ajusta esta URL a tu Django (ej. 'finance/tipos-movimiento/')
    final response = await _api.get('finance/tipomovimiento/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => TipoMovimiento.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar tipos de movimiento');
    }
  }

  // Método para obtener los tipos de transacción
  Future<List<TipoTransaccion>> getTiposTransaccion() async {
    // IMPORTANTE: Ajusta esta URL a tu Django (ej. 'finance/tipos-transaccion/')
    final response = await _api.get('finance/tipotransaccion/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => TipoTransaccion.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar tipos de transacción');
    }
}
// Método para obtener las SubCategorías
  Future<List<SubCategoria>> getSubCategorias() async {
    // IMPORTANTE: Asegúrate de tener esta ruta en tu urls.py de Django
    final response = await _api.get('finance/subcategoria/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => SubCategoria.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar subcategorías');
    }
  }
}