import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finanzas/cuenta_corriente.dart';
import '../models/finanzas/movimiento_cuenta.dart';
import 'crear_movimiento_cuenta_screen.dart'; 
import '../services/finance_service.dart';
import 'detalle_movimiento_screen.dart'; // Importamos la pantalla de detalles

class MovimientosCuentaScreen extends StatefulWidget {
  final CuentaCorriente cuenta; // Recibimos la cuenta al abrir la pantalla

  const MovimientosCuentaScreen({super.key, required this.cuenta});

  @override
  State<MovimientosCuentaScreen> createState() => _MovimientosCuentaScreenState();
}

class _MovimientosCuentaScreenState extends State<MovimientosCuentaScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<MovimientoCuenta>> _movimientosFuture;

  @override
  void initState() {
    super.initState();
    // Pedimos los movimientos de ESTA cuenta específica
    _movimientosFuture = _service.getMovimientosPorCuenta(widget.cuenta.idCuentaCorriente);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos de ${widget.cuenta.personaNombre ?? "Desconocido"}'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<MovimientoCuenta>>(
        future: _movimientosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Esta cuenta no tiene movimientos.'));
          }

          final movimientos = snapshot.data!;

          return ListView.builder(
            
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final mov = movimientos[index];
              final fecha = mov.fechaRegistro != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(mov.fechaRegistro!)
                  : 'Sin fecha';
// ... dentro de tu ListView.builder ...
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalleMovimientoScreen(
                        cuenta: widget.cuenta,
                        movimiento: mov,
                      ),
                    ),
                  ).then((value) {
                    // Si regresamos después de registrar un pago, recargamos los saldos
                    if (value == true) {
                      setState(() {
                        _movimientosFuture = _service.getMovimientosPorCuenta(widget.cuenta.idCuentaCorriente);
                      });
                    }
                  });
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            mov.tipoMovimientoNombre ?? 'Tipo desconocido',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Mostramos el monto original del contrato
                          Text(
                            'Monto Inicial: ${widget.cuenta.monedaSimbolo} ${mov.montoInicial.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          // Mostramos lo que falta por pagar
                          Text(
                            'Pendiente: ${widget.cuenta.monedaSimbolo} ${mov.saldoPendiente.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              // Naranja si aún hay deuda, verde si ya se pagó todo (saldo 0)
                              color: mov.saldoPendiente > 0 ? Colors.orange.shade700 : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              );
              
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () async {
          // Navegamos al formulario y le pasamos la cuenta actual
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              // Asegúrate de que el nombre coincida exactamente con la clase de tu otro archivo
              builder: (context) => CrearMovimientoScreen(cuenta: widget.cuenta),
            ),
          );

          // Si el formulario devolvió 'true' (se guardó exitosamente), recargamos la lista
          if (resultado == true) {
            setState(() {
              _movimientosFuture = _service.getMovimientosPorCuenta(widget.cuenta.idCuentaCorriente);
            });
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Movimiento añadido exitosamente!'), backgroundColor: Colors.green),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}