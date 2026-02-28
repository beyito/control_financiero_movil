import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/persona.dart'; // Asegúrate de importar donde guardaste la clase Persona
import 'crear_persona_screen.dart';
import '../services/finance_service.dart';

class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<Persona>> _personasFuture;

  @override
  void initState() {
    super.initState();
    _personasFuture = _service.getPersonas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personas Registradas'),
      ),
      body: FutureBuilder<List<Persona>>(
        future: _personasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay personas registradas.'));
          }

          final personas = snapshot.data!;

          return ListView.builder(
            itemCount: personas.length,
            itemBuilder: (context, index) {
              final persona = personas[index];
              
              // Formateamos la fecha de registro si existe
              final fecha = persona.fechaRegistro != null 
                  ? DateFormat('dd/MM/yyyy').format(persona.fechaRegistro!)
                  : 'Sin fecha';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  title: Text(
                    persona.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(persona.descripcion ?? 'Sin descripción'),
                  trailing: Text(
                    fecha,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
      // Arriba: import 'crear_persona_screen.dart';
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearPersonaScreen()),
          );
          // Si devuelve true, recargamos la lista
          if (resultado == true) {
            setState(() {
              _personasFuture = _service.getPersonas();
            });
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}