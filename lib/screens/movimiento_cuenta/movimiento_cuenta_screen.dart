import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finanzas/cuenta_corriente.dart';
import '../../models/finanzas/movimiento_cuenta.dart';
import 'crear_movimiento_cuenta_screen.dart'; 
import '../../services/finance_service.dart';
import 'detalle_movimiento_screen.dart'; 

class MovimientosCuentaScreen extends StatefulWidget {
  final CuentaCorriente cuenta; 

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
    _movimientosFuture = _service.getMovimientosPorCuenta(widget.cuenta.idCuentaCorriente);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo ultra limpio
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movimientos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF2D3142))),
            Text(widget.cuenta.personaNombre ?? "Desconocido", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<MovimientoCuenta>>(
        future: _movimientosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Sin movimientos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  const Text('Registra un préstamo o deuda aquí', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final movimientos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final mov = movimientos[index];
              final fecha = mov.fechaRegistro != null 
                  ? DateFormat('dd MMM yyyy').format(mov.fechaRegistro!)
                  : 'Sin fecha';
              
              // Lógica visual: Si el saldo es 0, está pagado (Verde). Si no, está pendiente (Naranja)
              final bool estaPagado = mov.saldoPendiente <= 0;
              final Color colorEstado = estaPagado ? const Color(0xFF38EF7D) : const Color(0xFFFC4A1A);
              final Color colorFondoIcono = estaPagado ? Colors.green.shade50 : Colors.orange.shade50;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleMovimientoScreen(cuenta: widget.cuenta, movimiento: mov),
                        ),
                      ).then((value) {
                        if (value == true) {
                          // LA CURA: Usar llaves {} en lugar de =>
                          setState(() {
                            _movimientosFuture = _service.getMovimientosPorCuenta(widget.cuenta.idCuentaCorriente);
                          });
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: colorFondoIcono, borderRadius: BorderRadius.circular(14)),
                                    child: Icon(Icons.swap_horiz, color: colorEstado, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mov.tipoMovimientoNombre ?? 'Movimiento',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                              // Etiqueta de estado
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  estaPagado ? 'Completado' : 'Pendiente',
                                  style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Monto Inicial', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.cuenta.monedaSimbolo} ${mov.montoInicial.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Por pagar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.cuenta.monedaSimbolo} ${mov.saldoPendiente.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 16,
                                      color: colorEstado,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0052D4), Color(0xFF6FB1FC)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF0052D4).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nuevo Movimiento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CrearMovimientoScreen(cuenta: widget.cuenta)),
            );
            if (resultado == true) {
              // LA CURA: Usar llaves {} en lugar de =>
              setState(() {
                _movimientosFuture = _service.getMovimientosPorCuenta(widget.cuenta.idCuentaCorriente);
              });
            }
          },
        ),
      ),
    );
  }
}