import 'package:flutter/material.dart';
import '../../services/finance_service.dart';
import '../../services/catalogo_service.dart';
import '../../models/catalogos/metodo_pago.dart';
import '../../models/catalogos/tipo_movimiento.dart'; 
import '../../models/finanzas/cuenta_corriente.dart'; 

class CrearMovimientoScreen extends StatefulWidget {
  final CuentaCorriente cuenta; 
  const CrearMovimientoScreen({super.key, required this.cuenta});

  @override
  State<CrearMovimientoScreen> createState() => _CrearMovimientoScreenState();
}

class _CrearMovimientoScreenState extends State<CrearMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final FinanceService _financeService = FinanceService();
  final CatalogoService _categoriaService = CatalogoService(); 
  
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController(); 

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
        _financeService.getTiposMovimiento(), 
        _categoriaService.getMetodosPago(),   
      ]);

      setState(() {
        _tiposMovimiento = respuestas[0] as List<TipoMovimiento>; 
        _metodosPago = respuestas[1] as List<MetodoPago>;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  void _guardarMovimiento() async {
    if (_formKey.currentState!.validate()) {
      if (_tipoMovimientoSeleccionado == null || _metodoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos obligatorios'), backgroundColor: Colors.orange));
        return;
      }

      setState(() => _isSaving = true);

      Map<String, dynamic> datos = {
        'cuenta_corriente': widget.cuenta.idCuentaCorriente, 
        'tipo_movimiento': _tipoMovimientoSeleccionado,
        'monto_inicial': _montoController.text,
        'metodo_pago_id': _metodoSeleccionado, 
        if (_conceptoController.text.isNotEmpty) 'concepto': _conceptoController.text, 
      };

      bool exito = await _financeService.crearMovimientoCuenta(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        Navigator.pop(context, true); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocurrió un error al guardar.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo limpio
      appBar: AppBar(
        title: const Text('Nuevo Movimiento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0052D4)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Resumen de la persona (Minimalista)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF0052D4).withOpacity(0.1),
                              radius: 24,
                              child: const Icon(Icons.person, color: Color(0xFF0052D4)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.cuenta.personaNombre ?? 'Persona', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                                  Text('Cuenta en ${widget.cuenta.monedaSimbolo}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 2. Monto Inicial (Estilo Billetera)
                      const Center(child: Text('Monto del Movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
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
                        validator: (value) => value!.isEmpty ? 'Ingresa el monto' : null,
                      ),
                      const SizedBox(height: 40),

                      // 3. Tipo de Movimiento (Chips)
                      const Text('Tipo de Movimiento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _tiposMovimiento.map((tipo) {
                          final isSelected = _tipoMovimientoSeleccionado == tipo.idTipoMovimiento;
                          return ChoiceChip(
                            label: Text(tipo.nombre),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2D3142),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) => setState(() => _tipoMovimientoSeleccionado = tipo.idTipoMovimiento),
                            selectedColor: const Color(0xFF0052D4),
                            backgroundColor: const Color(0xFFF5F7FA),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // 4. Método de Pago (Dropdown)
                      const Text('Desembolso / Medio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF0052D4)),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        hint: const Text('Método de Pago'),
                        value: _metodoSeleccionado,
                        items: _metodosPago.map((metodo) {
                          return DropdownMenuItem<int>(
                            value: metodo.idMetodoPago,
                            child: Text(metodo.nombre, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                          );
                        }).toList(),
                        onChanged: (int? newValue) => setState(() => _metodoSeleccionado = newValue),
                      ),
                      const SizedBox(height: 24),

                      // 5. Concepto (Texto Multilínea)
                      TextFormField(
                        controller: _conceptoController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Concepto (Opcional)',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 20.0), 
                            child: Icon(Icons.description_outlined, color: Color(0xFF0052D4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 6. Botón Guardar
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0052D4), Color(0xFF6FB1FC)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF0052D4).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSaving ? null : _guardarMovimiento,
                          child: _isSaving
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Guardar Movimiento', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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