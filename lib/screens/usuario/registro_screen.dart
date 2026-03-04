import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  DateTime? _fechaNacimiento;
  bool _isLoading = false;

  void _seleccionarFecha() async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 años atrás
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A00E0)),
          ),
          child: child!,
        );
      },
    );

    if (seleccion != null) {
      setState(() {
        _fechaNacimiento = seleccion;
      });
    }
  }

void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, dynamic> datos = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'nombre': _nombreController.text,
        if (_apellidoController.text.isNotEmpty) 'apellido': _apellidoController.text,
        if (_emailController.text.isNotEmpty) 'email': _emailController.text,
        if (_fechaNacimiento != null) 'fecha_nacimiento': DateFormat('yyyy-MM-dd').format(_fechaNacimiento!),
      };

      bool exitoso = await _authService.registrarUsuario(datos);

      setState(() => _isLoading = false);

      if (exitoso && mounted) {
        // --- SNACKBAR PREMIUM DE BIENVENIDA (ÉXITO) ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF11998E), // Verde principal de tu app
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            elevation: 10,
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Bienvenido!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Cuenta creada con éxito. Ya puedes iniciar sesión.', style: TextStyle(fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        
        Navigator.pop(context); // Lo mandamos de vuelta al Login
        
      } else if (mounted) {
        // --- SNACKBAR PREMIUM DE ERROR ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            elevation: 10,
            content: const Row(
              children: [
                Icon(Icons.person_off_outlined, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No se pudo registrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Es posible que el nombre de usuario ya exista. Intenta con otro.', style: TextStyle(fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECCIÓN: ACCESO ---
                const Text('Credenciales de Acceso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                
                _buildCustomTextField(
                  controller: _usernameController,
                  label: 'Nombre de usuario',
                  icon: Icons.alternate_email,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
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
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 40),

                // --- SECCIÓN: DATOS PERSONALES ---
                const Text('Datos Personales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        controller: _nombreController,
                        label: 'Nombre',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCustomTextField(
                        controller: _apellidoController,
                        label: 'Apellido (Opc.)',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildCustomTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico (Opc.)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                // Selector de Fecha
                InkWell(
                  onTap: _seleccionarFecha,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Color(0xFF4A00E0)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha de Nacimiento (Opc.)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              _fechaNacimiento != null ? DateFormat('dd MMM yyyy').format(_fechaNacimiento!) : 'Seleccionar fecha',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _fechaNacimiento != null ? const Color(0xFF2D3142) : Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),

                // --- BOTÓN REGISTRO ---
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
                    onPressed: _isLoading ? null : _registrar,
                    child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Comenzar ahora', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget reutilizable
  Widget _buildCustomTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: const Color(0xFF4A00E0)),
      ),
    );
  }
}