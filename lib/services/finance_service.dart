import 'dart:convert';
import '../models/finanzas/transaccion.dart'; // Importamos los modelos que creamos
import '../models/finanzas/movimiento_cuenta.dart'; // Importamos los modelos que creamos
import '../models/finanzas/cuenta_corriente.dart'; // Importamos los modelos que creamos
import '../models/catalogos/tipo_movimiento.dart'; // Importamos los modelos que creamos
import '../models/persona.dart';
import 'api_service.dart';

class DashboardData {
  final double saldoGlobal;
  final List<Transaccion> transacciones;

  DashboardData({required this.saldoGlobal, required this.transacciones});
}

class FinanceService {
  final ApiService _api = ApiService();

  // 2. Método unificado que trae ambos datos al mismo tiempo
  Future<DashboardData> getDashboardData() async {
    // Hacemos las dos peticiones al backend en paralelo para que sea más rápido
    final peticionTransacciones = _api.get('finance/transaccion/');
    final peticionResumen = _api.get('finance/resumen/'); // La nueva ruta de Django

    // Esperamos a que ambas respondan
    final respuestas = await Future.wait([peticionTransacciones, peticionResumen]);

    final responseTransacciones = respuestas[0];
    final responseResumen = respuestas[1];

    if (responseTransacciones.statusCode == 200 && responseResumen.statusCode == 200) {
      // Parseamos la lista de transacciones
      List<dynamic> jsonList = jsonDecode(responseTransacciones.body);
      List<Transaccion> lista = jsonList.map((item) => Transaccion.fromJson(item)).toList();

      // Parseamos el saldo global
      Map<String, dynamic> jsonResumen = jsonDecode(responseResumen.body);
      double saldo = double.tryParse(jsonResumen['saldo_global'].toString()) ?? 0.0;

      return DashboardData(saldoGlobal: saldo, transacciones: lista);
    } else {
      throw Exception('Error al cargar los datos del dashboard');
    }
  }
  // Obtener todas las transacciones
  Future<List<Transaccion>> getTransacciones({String? fechaInicio, String? fechaFin}) async {
    String url = 'finance/transaccion/'; // Ajusta tu URL base
    
    // Si la pantalla nos mandó fechas, las agregamos a la petición
    if (fechaInicio != null && fechaFin != null) {
      url += '?fecha_inicio=$fechaInicio&fecha_fin=$fechaFin';
    }

    final response = await _api.get(url); 
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => Transaccion.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar transacciones');
    }
  }
  // Método para crear una nueva transacción
  Future<bool> crearTransaccion(Map<String, dynamic> datos) async {
    // IMPORTANTE: Asegúrate de que esta URL acepte peticiones POST en tu Django
    final response = await _api.post('finance/transaccion/', datos);

    // Django REST Framework devuelve 201 (Created) cuando se guarda con éxito
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print('Error al crear transacción: ${response.body}');
      return false;
    }
  }

  Future<bool> actualizarTransaccion(int idTransaccion, Map<String, dynamic> datos) async {
    // IMPORTANTE: Asegúrate de que esta URL acepte peticiones PUT/PATCH en tu Django
    final response = await _api.patch('finance/transaccion/$idTransaccion/', datos);

    // Django REST Framework devuelve 200 (OK) o 204 (No Content) cuando se actualiza con éxito
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      print('Error al editar transacción: ${response.body}');
      return false;
    }
  }
  // Método para obtener la lista de personas
  Future<List<Persona>> getPersonas() async {
    // IMPORTANTE: Ajusta esta ruta a la de tu backend. 
    // Como tienes path('api/', include('usuario.urls')), probablemente sea algo como 'api/personas/'
    final response = await _api.get('api/persona/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => Persona.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar las personas: ${response.statusCode}');
    }
  }

  // Obtener todas las Cuentas Corrientes
  Future<List<CuentaCorriente>> getCuentasCorrientes() async {
    final response = await _api.get('finance/cuentacorriente/'); // Ajusta la URL si es distinta
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => CuentaCorriente.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar las cuentas corrientes');
    }
  }

  // Obtener los Movimientos de una Cuenta específica
  Future<List<MovimientoCuenta>> getMovimientosPorCuenta(int idCuenta) async {
    // Aquí asumimos que en Django puedes filtrar por cuenta_corriente
    // Ej: /finance/movimientos/?cuenta_corriente=1
    final response = await _api.get('finance/movimientocuenta/?cuenta_corriente=$idCuenta'); 
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => MovimientoCuenta.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar los movimientos');
    }
  }

  // Método para crear una nueva Persona
  Future<bool> crearPersona(Map<String, dynamic> datos) async {
    // IMPORTANTE: Ajusta esta URL según tu Django (ej. 'api/personas/')
    final response = await _api.post('api/persona/', datos);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print('Error al crear persona: ${response.body}');
      return false;
    }
  }

  // Método para crear una nueva Cuenta Corriente
  Future<bool> crearCuentaCorriente(Map<String, dynamic> datos) async {
    // IMPORTANTE: Ajusta esta URL según tu Django (ej. 'finance/cuentas/')
    final response = await _api.post('finance/cuentacorriente/', datos);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print('Error al crear cuenta: ${response.body}');
      return false;
    }
  }

  // Método para obtener los Tipos de Movimiento
  Future<List<TipoMovimiento>> getTiposMovimiento() async {
    // IMPORTANTE: Ajusta esta URL según tu Django (ej. 'finance/tipos-movimiento/')
    final response = await _api.get('finance/tipomovimiento/'); 

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => TipoMovimiento.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar tipos de movimiento');
    }
  }

  // Método para crear un nuevo Movimiento de Cuenta
  Future<bool> crearMovimientoCuenta(Map<String, dynamic> datos) async {
    // IMPORTANTE: Ajusta esta URL según tu Django (ej. 'finance/movimientos/')
    final response = await _api.post('finance/movimientocuenta/', datos);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print('Error al crear movimiento: ${response.body}');
      return false;
    }
  }

  // Obtener transacciones de un movimiento específico
  Future<List<Transaccion>> getTransaccionesPorMovimiento(int idMovimiento) async {
    // Django REST Framework permite filtrar si lo configuras, ej: ?movimiento_cuenta=1
    final response = await _api.get('finance/transaccion/?movimiento_cuenta=$idMovimiento'); 
    
    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((item) => Transaccion.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar pagos del movimiento');
    }
  }

  // Anular Transacción
  Future<bool> eliminarTransaccion(int idTransaccion) async {
    // Usamos tu método genérico de API (si tienes .delete configurado) 
    // Si no tienes un método .delete en tu ApiService, usa http.delete directamente con tu token.
    final response = await _api.delete('finance/transaccion/$idTransaccion/');
    
    // Django REST Framework devuelve 204 No Content cuando un DELETE es exitoso
    if (response.statusCode == 204 || response.statusCode == 200) {
      return true;
    }
    return false;
  }

  // Anular Transacción
  Future<bool> eliminarMovimiento(int idMovimientoCuenta) async {
    // Usamos tu método genérico de API (si tienes .delete configurado) 
    // Si no tienes un método .delete en tu ApiService, usa http.delete directamente con tu token.
    final response = await _api.delete('finance/movimientocuenta/$idMovimientoCuenta/');
    
    // Django REST Framework devuelve 204 No Content cuando un DELETE es exitoso
    if (response.statusCode == 204 || response.statusCode == 200) {
      return true;
    }
    return false;
  }

  // Obtener los saldos históricos de todas las monedas
  Future<Map<int, double>> getSaldosGlobales() async {
    // Asegúrate de que esta URL sea la de tu ResumenDashboardView
    final response = await _api.get('finance/resumen/'); 
    
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      Map<int, double> saldos = {};
      
      // Recorremos el JSON que nos mandó Django
      data.forEach((key, value) {
        // key es el ID de la moneda (ej. "1")
        // value es el mapa interno con los totales
        int idMoneda = int.parse(key);
        double saldoHistorial = double.parse(value['saldo_global'].toString());
        
        saldos[idMoneda] = saldoHistorial;
      });
      
      return saldos;
    } else {
      throw Exception('Error al cargar los saldos globales');
    }
  }
}

