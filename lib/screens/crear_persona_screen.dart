import 'package:flutter/material.dart';
import '../services/finance_service.dart';

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
        // La descripción es opcional, la enviamos si hay texto
        if (_descripcionController.text.isNotEmpty) 'descripcion': _descripcionController.text,
      };

      bool exito = await _financeService.crearPersona(datos);

      setState(() => _isLoading = false);

      if (exito && mounted) {
        Navigator.pop(context, true); // Devuelve true si fue exitoso
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar la persona.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Persona')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) => value!.isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                      onPressed: _guardarPersona,
                      child: const Text('Guardar Persona', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}