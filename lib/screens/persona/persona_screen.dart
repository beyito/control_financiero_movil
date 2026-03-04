import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/persona.dart'; 
import 'crear_persona_screen.dart';
import '../../services/finance_service.dart';

class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<Persona>> _personasFuture;

  // Paleta de colores dinámicos para los avatares
  final List<Color> _avatarColors = [
    const Color(0xFF4A00E0), // Morado
    const Color(0xFF11998E), // Verde
    const Color(0xFFFC4A1A), // Naranja
    const Color(0xFF0052D4), // Azul
    const Color(0xFFE81CFF), // Rosa
    const Color(0xFFF6D365), // Amarillo
  ];

  @override
  void initState() {
    super.initState();
    _personasFuture = _service.getPersonas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Directorio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<Persona>>(
        future: _personasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                    child: const Icon(Icons.group_outlined, size: 80, color: Color(0xFFB0BEC5)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Directorio vacío', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  const Text('Añade a las personas con las que transaccionas', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            );
          }

          final personas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100, left: 16, right: 16),
            itemCount: personas.length,
            itemBuilder: (context, index) {
              final persona = personas[index];
              final fecha = persona.fechaRegistro != null 
                  ? DateFormat('dd MMM yyyy').format(persona.fechaRegistro!)
                  : 'Sin fecha';

              final avatarColor = _avatarColors[index % _avatarColors.length];
              final inicial = persona.nombre.isNotEmpty ? persona.nombre[0].toUpperCase() : '?';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor.withOpacity(0.15),
                    child: Text(inicial, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  title: Text(persona.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(persona.descripcion ?? 'Sin descripción', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  trailing: Text(fecha, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text('Añadir Persona', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CrearPersonaScreen()),
            );
            if (resultado == true) {
              // LA CURA: Usar llaves {} en lugar de =>
              setState(() {
                _personasFuture = _service.getPersonas();
              });
            }
          },
        ),
      ),
    );
  }
}