import 'package:flutter/material.dart';
import '../../services/finance_service.dart';
import '../../services/catalogo_service.dart';
import '../../models/catalogos/metodo_pago.dart';
import '../../models/finanzas/cuenta_corriente.dart';
import '../../models/finanzas/movimiento_cuenta.dart';

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
    _montoController.text = widget.movimiento.saldoPendiente.toStringAsFixed(2);
    _cargarDatos();
  }

  void _cargarDatos() async {
    try {
      final metodos = await _catalogoService.getMetodosPago();
      setState(() {
        _metodosPago = metodos;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar métodos de pago: $e')));
      }
    }
  }

  void _guardarPago() async {
    if (_formKey.currentState!.validate()) {
      if (_metodoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona un método de pago'), backgroundColor: Colors.orange));
        return;
      }

      setState(() => _isSaving = true);

      Map<String, dynamic> datos = {
        'monto': _montoController.text,
        'metodo_pago': _metodoSeleccionado,
        'movimiento_cuenta': widget.movimiento.idMovimientoCuenta, 
      };

      bool exito = await _financeService.crearTransaccion(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado con éxito'), backgroundColor: Color(0xFF38EF7D)));
        Navigator.pop(context, true); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al registrar el pago.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo limpio
      appBar: AppBar(
        title: const Text('Registrar Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF11998E)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de resumen visual Premium
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF11998E).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.receipt_long, color: Color(0xFF11998E), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SALDO PENDIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.cuenta.monedaSimbolo} ${widget.movimiento.saldoPendiente.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Input de Monto a Pagar estilo "Transferencia"
                      const Center(child: Text('Monto a Pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 10),
                            child: Text(widget.cuenta.monedaSimbolo ?? '\$', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey.shade300),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          double? montoPagar = double.tryParse(value);
                          if (montoPagar != null && montoPagar > widget.movimiento.saldoPendiente) {
                            return 'El monto supera el saldo pendiente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Método de Pago (Estilo moderno lleno)
                      const Text('Método de Pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF11998E)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        hint: const Text('Selecciona el método'),
                        value: _metodoSeleccionado,
                        items: _metodosPago.map((metodo) {
                          return DropdownMenuItem<int>(
                            value: metodo.idMetodoPago, 
                            child: Text(metodo.nombre, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)))
                          );
                        }).toList(),
                        onChanged: (int? newValue) => setState(() => _metodoSeleccionado = newValue),
                      ),
                      const SizedBox(height: 40),

                      // Botón Guardar Pago con Degradado
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]), // Verde Neón/Esmeralda
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF11998E).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSaving ? null : _guardarPago,
                          child: _isSaving
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Confirmar Pago', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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