import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finanzas/cuenta_corriente.dart';
import '../../models/finanzas/movimiento_cuenta.dart';
import '../../models/finanzas/transaccion.dart';
import '../../services/finance_service.dart';
import 'crear_pago_screen.dart'; 

class DetalleMovimientoScreen extends StatefulWidget {
  final CuentaCorriente cuenta;
  final MovimientoCuenta movimiento;

  const DetalleMovimientoScreen({super.key, required this.cuenta, required this.movimiento});

  @override
  State<DetalleMovimientoScreen> createState() => _DetalleMovimientoScreenState();
}

class _DetalleMovimientoScreenState extends State<DetalleMovimientoScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<Transaccion>> _pagosFuture;

  @override
  void initState() {
    super.initState();
    _cargarPagos();
  }

  void _cargarPagos() {
    _pagosFuture = _service.getTransaccionesPorMovimiento(widget.movimiento.idMovimientoCuenta);
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos para la barra de progreso
    final double totalPagado = widget.movimiento.montoInicial - widget.movimiento.saldoPendiente;
    double porcentajePagado = 0.0;
    if (widget.movimiento.montoInicial > 0) {
      porcentajePagado = totalPagado / widget.movimiento.montoInicial;
    }
    final bool estaPagado = widget.movimiento.saldoPendiente <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo claro
      appBar: AppBar(
        title: const Text('Detalle de Movimiento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Anular Movimiento',
            onPressed: () async {
              bool confirmar = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('¿Anular Movimiento?'),
                  content: const Text('Este Movimiento se anulará y los saldos se recalcularán automáticamente. ¿Deseas continuar?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sí, anular', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ) ?? false;

              if (confirmar && context.mounted) {
                bool exito = await _service.eliminarMovimiento(widget.movimiento.idMovimientoCuenta);
                if (exito && context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TARJETA DE RESUMEN Y PROGRESO
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0052D4), Color(0xFF4364F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF0052D4).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SALDO PENDIENTE', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        estaPagado ? 'COMPLETADO' : 'EN PROCESO',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.cuenta.monedaSimbolo} ${widget.movimiento.saldoPendiente.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                // Barra de Progreso
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pagado: ${widget.cuenta.monedaSimbolo} ${totalPagado.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('Total: ${widget.cuenta.monedaSimbolo} ${widget.movimiento.montoInicial.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: porcentajePagado,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38EF7D)), // Verde brillante
                  ),
                ),
              ],
            ),
          ),

          // TÍTULO DE LA LISTA
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Historial de Transacciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            ),
          ),

          // LISTA DE TRANSACCIONES (PAGOS)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: FutureBuilder<List<Transaccion>>(
                future: _pagosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aún no hay pagos registrados.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    );
                  }

                  final pagos = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 24, bottom: 100, left: 24, right: 24),
                    itemCount: pagos.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFFF0F0F0), height: 24),
                    itemBuilder: (context, index) {
                      final pago = pagos[index];
                      final fecha = pago.fechaRegistro != null 
                          ? DateFormat('dd MMM yyyy, HH:mm').format(pago.fechaRegistro!) : '';
                      
                      final esIngreso = pago.tipoTransaccionNombre?.toLowerCase().contains('ingreso') ?? false;

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: esIngreso ? Colors.green.shade50 : Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(esIngreso ? Icons.arrow_downward : Icons.arrow_upward, 
                                color: esIngreso ? Colors.green : Colors.red, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pago.subcategoriaNombre ?? 'Pago', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                                const SizedBox(height: 4),
                                Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            '${esIngreso ? '+' : '-'}${widget.cuenta.monedaSimbolo} ${pago.monto.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: esIngreso ? Colors.green : Colors.red),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.movimiento.saldoPendiente > 0 
        ? Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]), // Verde Neón
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: const Color(0xFF11998E).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('Registrar Pago', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CrearPagoScreen(cuenta: widget.cuenta, movimiento: widget.movimiento)),
                );
                if (resultado == true) Navigator.pop(context, true); 
              },
            ),
          )
        : null, 
    );
  }
}