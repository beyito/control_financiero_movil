// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class Config {
//   // Lógica para devolver la URL correcta dependiendo del entorno
//   static String get apiUrl {
//     final environment = dotenv.env['ENVIRONMENT'] ?? 'local';
    
//     if (environment == 'production') {
//       return dotenv.env['API_URL_PROD'] ?? '';
//     }
    
//     return dotenv.env['API_URL_LOCAL'] ?? '';
//   }
// }

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get apiUrl {
    return dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/';
  }
}