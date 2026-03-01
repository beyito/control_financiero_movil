import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'registro_screen.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _iniciarSesion() async {
    setState(() => _isLoading = true);
    
    bool exitoso = await AuthService().login(
      _usernameController.text, 
      _passwordController.text
    );

    setState(() => _isLoading = false);

    if (exitoso && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()), 
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo ultra limpio
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO / ICONO PRINCIPAL ---
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 40),

                // --- TEXTOS DE BIENVENIDA ---
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión para gestionar tus finanzas',
                  style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),

                // --- FORMULARIO ---
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4A00E0)),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4A00E0)),
                  ),
                ),
                const SizedBox(height: 40),

                // --- BOTÓN ENTRAR ---
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, 
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _iniciarSesion,
                    child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 24),

                // --- TEXTO PARA REGISTRARSE ---
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistroScreen()), 
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                      children: [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(color: Color(0xFF4A00E0), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}