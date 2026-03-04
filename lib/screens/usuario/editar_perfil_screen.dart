import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> perfilActual;

  const EditarPerfilScreen({super.key, required this.perfilActual});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _usuarioController;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  DateTime? _fechaNacimiento;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usuarioController = TextEditingController(text: widget.perfilActual['username'] ?? '');
    _nombreController = TextEditingController(text: widget.perfilActual['first_name'] ?? '');
    _apellidoController = TextEditingController(text: widget.perfilActual['last_name'] ?? '');
    _emailController = TextEditingController(text: widget.perfilActual['email'] ?? '');
    _passwordController = TextEditingController(); 

    if (widget.perfilActual['fecha_nacimiento'] != null) {
      _fechaNacimiento = DateTime.tryParse(widget.perfilActual['fecha_nacimiento']);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 6570)), 
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

    if (seleccionada != null && seleccionada != _fechaNacimiento) {
      setState(() => _fechaNacimiento = seleccionada);
    }
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      Map<String, dynamic> datos = {
        'username': _usuarioController.text,
        'first_name': _nombreController.text,
        'last_name': _apellidoController.text,
        'email': _emailController.text,
      };

      if (_fechaNacimiento != null) {
        datos['fecha_nacimiento'] = DateFormat('yyyy-MM-dd').format(_fechaNacimiento!);
      }

      if (_passwordController.text.isNotEmpty) {
        datos['password'] = _passwordController.text;
      }

      bool exito = await _authService.actualizarPerfil(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        // --- SNACKBAR PREMIUM DE ÉXITO ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF11998E), // Tu verde principal
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            elevation: 10,
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Perfil Actualizado Exitósamente!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context, true);
        
      } else if (mounted) {
        // --- SNACKBAR DE ERROR (Opcional, por si falla el backend) ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al actualizar el perfil. Intenta de nuevo.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco total para formularios
      appBar: AppBar(
        title: const Text('Editar Cuenta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                // SECCIÓN: DATOS PERSONALES
                const Text('Datos Personales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),

                _buildCustomTextField(
                  controller: _usuarioController,
                  label: 'Nombre de Usuario',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        controller: _nombreController,
                        label: 'Nombre',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCustomTextField(
                        controller: _apellidoController,
                        label: 'Apellido',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildCustomTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Selector de Fecha Estilizado
                InkWell(
                  onTap: () => _seleccionarFecha(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Color(0xFF4A00E0)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha de Nacimiento', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                const SizedBox(height: 40),

                // SECCIÓN: SEGURIDAD
                const Text('Seguridad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    hintText: 'Déjalo en blanco para no cambiar',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4A00E0)),
                  ),
                ),
                const SizedBox(height: 50),

                // BOTÓN GUARDAR
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
                    onPressed: _isSaving ? null : _guardarCambios,
                    child: _isSaving
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pequeño widget para no repetir el código de los TextFields
  Widget _buildCustomTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    TextInputType keyboardType = TextInputType.text
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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