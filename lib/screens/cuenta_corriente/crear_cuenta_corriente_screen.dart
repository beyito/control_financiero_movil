import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';
import '../../services/finance_service.dart';
import '../../models/catalogos/moneda.dart'; 
import '../../models/persona.dart'; 

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
      if (!mounted) return;
      setState(() {
        _personas = respuestas[0] as List<Persona>;
        _monedas = respuestas[1] as List<Moneda>;
        if (_monedas.isNotEmpty) _monedaSeleccionada = _monedas.first.idMoneda;
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _guardarCuenta() async {
    if (_formKey.currentState!.validate()) {
      if (_personaSeleccionada == null || _monedaSeleccionada == null) {
        // --- SNACKBAR DE ADVERTENCIA MEJORADO ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            elevation: 8,
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Por favor, selecciona persona y moneda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        );
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
                      Text('¡Cuenta Creada!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Se vinculó correctamente a la persona.', style: TextStyle(fontSize: 13, color: Colors.white)),
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
                  child: Text('Error al crear la cuenta. Intenta de nuevo.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      backgroundColor: Colors.white, // Fondo ultra limpio
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        title: const Text('Configurar Cuenta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera estilizada con ícono flotante
                      Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: const Icon(Icons.account_balance, size: 45, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      const Text('Titular de la cuenta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),

                      // Desplegable moderno
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA), // Gris azulado súper suave
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF4A00E0)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        hint: const Text('Selecciona una persona'),
                        value: _personaSeleccionada,
                        items: _personas.map((persona) {
                          return DropdownMenuItem<int>(
                            value: persona.idPersona, 
                            child: Text(persona.nombre, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                          );
                        }).toList(),
                        onChanged: (int? newValue) => setState(() => _personaSeleccionada = newValue),
                        validator: (value) => value == null ? 'Selecciona una persona' : null,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      const Text('Moneda principal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      
                      // Chips de selección de moneda dinámicos
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _monedas.map((moneda) {
                          final isSelected = _monedaSeleccionada == moneda.idMoneda;
                          return ChoiceChip(
                            label: Text('${moneda.simbolo}  ${moneda.nombre}'),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2D3142),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) => setState(() => _monedaSeleccionada = moneda.idMoneda),
                            selectedColor: const Color(0xFF4A00E0), // Color activo
                            backgroundColor: const Color(0xFFF5F7FA), // Color inactivo
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300, width: 1),
                            ),
                            elevation: isSelected ? 4 : 0,
                            shadowColor: const Color(0xFF4A00E0).withOpacity(0.4),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 50),

                      // Botón Guardar con Degradado
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Transparente para ver el degradado
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSaving ? null : _guardarCuenta,
                          child: _isSaving
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Crear Cuenta', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
}