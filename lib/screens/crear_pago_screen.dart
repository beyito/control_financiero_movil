import 'package:flutter/material.dart';
import '../services/finance_service.dart';
import '../services/catalogo_service.dart';
import '../models/catalogos/metodo_pago.dart';
import '../models/finanzas/cuenta_corriente.dart';
import '../models/finanzas/movimiento_cuenta.dart';

class CrearPagoScreen extends StatefulWidget {
  final CuentaCorriente cuenta;
  final MovimientoCuenta movimiento;

  const CrearPagoScreen({super.key, required this.cuenta, required this.movimiento});

  @override
  State<CrearPagoScreen> createState() => _CrearPagoScreenState();
}

class _CrearPagoScreenState extends State<CrearPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();
  
  final TextEditingController _montoController = TextEditingController();

  int? _metodoSeleccionado;
  
  bool _isLoadingData = true;
  bool _isSaving = false;

  List<MetodoPago> _metodosPago = [];

  @override
  void initState() {
    super.initState();
    // Pre-llenamos el monto con lo que falta pagar para ahorrarle tiempo al usuario
    _montoController.text = widget.movimiento.saldoPendiente.toStringAsFixed(2);
    _cargarDatos();
  }

  void _cargarDatos() async {
    try {
      // Ahora SOLO necesitamos descargar los métodos de pago
      final metodos = await _catalogoService.getMetodosPago();

      setState(() {
        _metodosPago = metodos;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar métodos de pago: $e')),
        );
      }
    }
  }

  void _guardarPago() async {
    if (_formKey.currentState!.validate()) {
      if (_metodoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona un método de pago')),
        );
        return;
      }

      setState(() => _isSaving = true);

      // Enviamos EXACTAMENTE los 3 datos solicitados a la API de transacciones
      Map<String, dynamic> datos = {
        'monto': _montoController.text,
        'metodo_pago': _metodoSeleccionado,
        'movimiento_cuenta': widget.movimiento.idMovimientoCuenta, 
      };

      // Asumimos que sigues usando el endpoint de crear transacción para registrar el pago
      bool exito = await _financeService.crearTransaccion(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        Navigator.pop(context, true); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al registrar el pago.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Pago'),
        backgroundColor: Colors.indigo,
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
                    // Tarjeta de resumen visual
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.indigo, size: 32),
                      title: Text('Saldo pendiente: ${widget.cuenta.monedaSimbolo} ${widget.movimiento.saldoPendiente.toStringAsFixed(2)}'),
                      subtitle: const Text('Registrando nuevo pago o cuota'),
                      tileColor: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 24),

                    // Monto a pagar
                    TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Monto del Pago',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 14.0, left: 16.0, right: 12.0),
                          child: Text(widget.cuenta.monedaSimbolo ?? '\$', style: const TextStyle(fontSize: 20)),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        // Validamos que no pague más del saldo pendiente
                        double? montoPagar = double.tryParse(value);
                        if (montoPagar != null && montoPagar > widget.movimiento.saldoPendiente) {
                          return 'El monto supera el saldo pendiente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Método de Pago
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      value: _metodoSeleccionado,
                      items: _metodosPago.map((metodo) {
                        return DropdownMenuItem<int>(
                          value: metodo.idMetodoPago, 
                          child: Text(metodo.nombre)
                        );
                      }).toList(),
                      onChanged: (int? newValue) => setState(() => _metodoSeleccionado = newValue),
                    ),
                    const SizedBox(height: 32),

                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo, 
                              padding: const EdgeInsets.symmetric(vertical: 16)
                            ),
                            onPressed: _guardarPago,
                            child: const Text('Guardar Pago', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}