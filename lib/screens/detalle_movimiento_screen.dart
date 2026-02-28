import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finanzas/cuenta_corriente.dart';
import '../models/finanzas/movimiento_cuenta.dart';
import '../models/finanzas/transaccion.dart';
import '../services/finance_service.dart';
import 'crear_pago_screen.dart'; // La crearemos en el paso 4

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Resumen del Préstamo arriba
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monto Inicial: ${widget.cuenta.monedaSimbolo} ${widget.movimiento.montoInicial.toStringAsFixed(2)}'),
                    const SizedBox(height: 5),
                    Text(
                      'Saldo Pendiente: ${widget.cuenta.monedaSimbolo} ${widget.movimiento.saldoPendiente.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: widget.movimiento.saldoPendiente > 0 ? Colors.orange.shade700 : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Lista de Transacciones (Pagos)
          Expanded(
            child: FutureBuilder<List<Transaccion>>(
              future: _pagosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aún no hay pagos registrados.'));
                }

                final pagos = snapshot.data!;
                return ListView.builder(
                  itemCount: pagos.length,
                  itemBuilder: (context, index) {
                    final pago = pagos[index];
                    final fecha = pago.fechaRegistro != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(pago.fechaRegistro!) : '';
                    
                    final esIngreso = pago.tipoTransaccionNombre?.toLowerCase().contains('ingreso') ?? false;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: esIngreso ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(esIngreso ? Icons.arrow_downward : Icons.arrow_upward, 
                                    color: esIngreso ? Colors.green : Colors.red),
                      ),
                      title: Text(pago.subcategoriaNombre ?? 'Pago'),
                      subtitle: Text(fecha),
                      trailing: Text(
                        '${widget.cuenta.monedaSimbolo} ${pago.monto.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.movimiento.saldoPendiente > 0 
        ? FloatingActionButton.extended(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.payment),
            label: const Text('Registrar Pago'),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CrearPagoScreen(cuenta: widget.cuenta, movimiento: widget.movimiento),
                ),
              );

              if (resultado == true) {
                // Notificamos a la pantalla anterior que debe recargar
                Navigator.pop(context, true); 
              }
            },
          )
        : null, // Si el saldo es 0, ocultamos el botón de pagar
    );
  }
}