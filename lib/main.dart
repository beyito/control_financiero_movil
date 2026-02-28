import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/main_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  runApp(const ControlFinancieroApp());
}

class ControlFinancieroApp extends StatelessWidget {
  const ControlFinancieroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Financiero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            return const MainScreen(); // <--- CÁMBIALO AQUÍ
          }

          return const LoginScreen(); 
        },
      ),
    );
  }
}