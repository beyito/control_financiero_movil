import 'package:flutter/material.dart';
import '../../services/finance_service.dart';

class CrearPersonaScreen extends StatefulWidget {
  const CrearPersonaScreen({super.key});

  @override
  State<CrearPersonaScreen> createState() => _CrearPersonaScreenState();
}

class _CrearPersonaScreenState extends State<CrearPersonaScreen> {
  final _formKey = GlobalKey<FormState>();
  final FinanceService _financeService = FinanceService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isLoading = false;

  void _guardarPersona() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, dynamic> datos = {
        'nombre': _nombreController.text,
        if (_descripcionController.text.isNotEmpty) 'descripcion': _descripcionController.text,
      };

      bool exito = await _financeService.crearPersona(datos);

      setState(() => _isLoading = false);

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
                      Text('¡Persona añadida con éxito!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                  child: Text('Error al guardar la persona. Intenta de nuevo.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nueva Persona', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                // Cabecera estilizada
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.person_outline, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
                
                const Text('Datos del Contacto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),

                // Campo de Nombre
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF4A00E0)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa el nombre' : null,
                ),
                const SizedBox(height: 20),

                // Campo de Descripción
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFF2D3142)),
                  decoration: InputDecoration(
                    labelText: 'Descripción o nota (Opcional)',
                    alignLabelWithHint: true, // Alinea el label arriba cuando es multiline
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40.0), // Sube el ícono
                      child: Icon(Icons.notes, color: Color(0xFF4A00E0)),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Botón Guardar con Degradado
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
                    onPressed: _isLoading ? null : _guardarPersona,
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Guardar Contacto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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