import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

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
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
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
        // Enviar solo si no están vacíos (opcionales)
        if (_apellidoController.text.isNotEmpty) 'apellido': _apellidoController.text,
        if (_emailController.text.isNotEmpty) 'email': _emailController.text,
        if (_fechaNacimiento != null) 'fecha_nacimiento': DateFormat('yyyy-MM-dd').format(_fechaNacimiento!),
      };

      bool exitoso = await _authService.registrarUsuario(datos);

      setState(() => _isLoading = false);

      if (exitoso && mounted) {
        // Mostramos mensaje y cerramos la pantalla de registro para volver al Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada con éxito! Ahora inicia sesión.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear la cuenta. El usuario podría ya existir.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta Nueva')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Datos de Acceso (Obligatorios)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nombre de usuario', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              
              const SizedBox(height: 32),
              const Text('Datos Personales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre (Obligatorio)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo Electrónico (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              // Selector de Fecha
              ListTile(
                title: Text(_fechaNacimiento == null 
                    ? 'Seleccionar Fecha de Nacimiento (Opcional)' 
                    : 'Nacimiento: ${DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)}'),
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                onTap: _seleccionarFecha,
              ),
              
              const SizedBox(height: 32),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _registrar,
                    child: const Text('Registrarme', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}