import 'package:flutter/material.dart';
import '../services/finance_service.dart';
import '../services/catalogo_service.dart';
import '../models/catalogos/metodo_pago.dart';
import '../models/catalogos/tipo_movimiento.dart'; 
import '../models/finanzas/cuenta_corriente.dart'; 

class CrearMovimientoScreen extends StatefulWidget {
  final CuentaCorriente cuenta; // Recibimos la cuenta
  const CrearMovimientoScreen({super.key, required this.cuenta});

  @override
  State<CrearMovimientoScreen> createState() => _CrearMovimientoScreenState();
}

class _CrearMovimientoScreenState extends State<CrearMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final FinanceService _financeService = FinanceService();
  final CatalogoService _categoriaService = CatalogoService(); // Tu nuevo servicio separado
  
  final TextEditingController _montoController = TextEditingController();

  int? _tipoMovimientoSeleccionado;
  int? _metodoSeleccionado;
  
  bool _isLoadingData = true;
  bool _isSaving = false;

  List<TipoMovimiento> _tiposMovimiento = [];
  List<MetodoPago> _metodosPago = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    try {
      final respuestas = await Future.wait([
        _financeService.getTiposMovimiento(), // Índice 0
        _categoriaService.getMetodosPago(),   // Índice 1
      ]);

      setState(() {
        // CORRECCIÓN: El índice 0 es para los Tipos de Movimiento
        _tiposMovimiento = respuestas[0] as List<TipoMovimiento>; 
        _metodosPago = respuestas[1] as List<MetodoPago>;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _guardarMovimiento() async {
    if (_formKey.currentState!.validate()) {
      if (_tipoMovimientoSeleccionado == null || _metodoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los campos obligatorios')),
        );
        return;
      }

      setState(() => _isSaving = true);

      // Creamos el JSON basado en tu modelo de Django MovimientoCuenta
      Map<String, dynamic> datos = {
        'cuenta_corriente': widget.cuenta.idCuentaCorriente, // ID de la cuenta actual
        'tipo_movimiento': _tipoMovimientoSeleccionado,
        'monto_inicial': _montoController.text,
        'metodo_pago_id': _metodoSeleccionado, // Este dato lo interceptará Django
      };

      bool exito = await _financeService.crearMovimientoCuenta(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        Navigator.pop(context, true); // Cerramos y enviamos "true" de éxito
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ocurrió un error al guardar.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Movimiento'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 1. Resumen de la persona
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        widget.cuenta.personaNombre ?? 'Persona',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Cuenta en ${widget.cuenta.monedaSimbolo}'),
                      tileColor: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 24),

                    // 2. Monto Inicial
                    TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Monto del Movimiento',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 14.0, left: 16.0, right: 12.0),
                          child: Text(
                            widget.cuenta.monedaSimbolo ?? '\$', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingresa el monto' : null,
                    ),
                    const SizedBox(height: 24),

                    // 3. Tipo de Movimiento (Ej: "Yo le presté", "Me prestó")
                    const Text('Tipo de Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12.0,
                      children: _tiposMovimiento.map((tipo) {
                        return ChoiceChip(
                          label: Text(tipo.nombre),
                          selected: _tipoMovimientoSeleccionado == tipo.idTipoMovimiento,
                          onSelected: (bool selected) => setState(() => _tipoMovimientoSeleccionado = tipo.idTipoMovimiento),
                          selectedColor: Colors.blue.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 4. Método de Pago (Dropdown)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago del Desembolso',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      value: _metodoSeleccionado,
                      items: _metodosPago.map((metodo) {
                        return DropdownMenuItem<int>(
                          value: metodo.idMetodoPago,
                          child: Text(metodo.nombre),
                        );
                      }).toList(),
                      onChanged: (int? newValue) => setState(() => _metodoSeleccionado = newValue),
                    ),
                    const SizedBox(height: 32),
                    
                    // 5. Botón Guardar
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _guardarMovimiento,
                            child: const Text('Guardar Movimiento', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}