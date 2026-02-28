import 'package:control_financiero/services/catalogo_service.dart';
import 'package:flutter/material.dart';
import '../services/finance_service.dart';
import '../models/catalogos/moneda.dart'; // Asegúrate de importar Moneda
import '../models/persona.dart'; // O donde tengas el modelo Persona

class CrearCuentaScreen extends StatefulWidget {
  const CrearCuentaScreen({super.key});

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();

  int? _personaSeleccionada;
  int? _monedaSeleccionada;

  bool _isLoadingData = true;
  bool _isSaving = false;

  List<Persona> _personas = [];
  List<Moneda> _monedas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    try {
      final respuestas = await Future.wait([
        _financeService.getPersonas(),
        _catalogoService.getMonedas(),
      ]);

      setState(() {
        _personas = respuestas[0] as List<Persona>;
        _monedas = respuestas[1] as List<Moneda>;
        if (_monedas.isNotEmpty) _monedaSeleccionada = _monedas.first.idMoneda;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  void _guardarCuenta() async {
    if (_formKey.currentState!.validate()) {
      if (_personaSeleccionada == null || _monedaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
        return;
      }

      setState(() => _isSaving = true);

      Map<String, dynamic> datos = {
        'persona': _personaSeleccionada,
        'moneda': _monedaSeleccionada,
      };

      bool exito = await _financeService.crearCuentaCorriente(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cuenta Corriente')),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Desplegable de Personas
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Selecciona la Persona', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      value: _personaSeleccionada,
                      items: _personas.map((persona) {
                        return DropdownMenuItem<int>(
                          value: persona.idPersona, // Asegúrate de que este sea el nombre de tu variable en el modelo Persona
                          child: Text(persona.nombre),
                        );
                      }).toList(),
                      onChanged: (int? newValue) => setState(() => _personaSeleccionada = newValue),
                      validator: (value) => value == null ? 'Selecciona una persona' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Selección de Moneda
                    const Text('Moneda de la Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12.0,
                      children: _monedas.map((moneda) {
                        return ChoiceChip(
                          label: Text('${moneda.simbolo} (${moneda.nombre})'),
                          selected: _monedaSeleccionada == moneda.idMoneda,
                          onSelected: (bool selected) => setState(() => _monedaSeleccionada = moneda.idMoneda),
                          selectedColor: Colors.blue.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Botón Guardar
                    Center(
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                              onPressed: _guardarCuenta,
                              child: const Text('Crear Cuenta', style: TextStyle(color: Colors.white, fontSize: 18)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}