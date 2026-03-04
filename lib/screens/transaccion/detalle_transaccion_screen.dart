import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finanzas/transaccion.dart'; 
import '../../services/finance_service.dart'; 
// Asegúrate de importar la pantalla que usaremos para editar:
import 'crear_transaccion_screen.dart'; // O 'editar_transaccion_screen.dart' si creas una separada

class DetalleTransaccionScreen extends StatelessWidget {
  final Transaccion transaccion;
  final String simboloMoneda;

  const DetalleTransaccionScreen({
    super.key, 
    required this.transaccion,
    required this.simboloMoneda,
  });

  @override
  Widget build(BuildContext context) {
    final esIngreso = (transaccion.tipoTransaccionNombre ?? '').toLowerCase().contains('ingreso') || 
                      (transaccion.tipoTransaccionNombre ?? '').toLowerCase().contains('entrada');
                      
    final List<Color> bgGradient = esIngreso 
        ? [const Color(0xFF11998E), const Color(0xFF38EF7D)] 
        : [const Color(0xFFFF5252), const Color(0xFFF77062)]; 
        
    // --- FORMATO DE FECHA COMPLETO ---
    final fechaCompleta = transaccion.fechaRegistro != null 
        ? DateFormat("EEEE, d 'de' MMMM 'de' yyyy, HH:mm", 'es_ES').format(transaccion.fechaRegistro!) 
        : 'Fecha no disponible';
        
    // Convertimos la primera letra de la fecha a mayúscula (ej: "domingo" -> "Domingo")
    final fechaFinal = transaccion.fechaRegistro != null 
        ? fechaCompleta[0].toUpperCase() + fechaCompleta.substring(1) 
        : fechaCompleta;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      appBar: AppBar(
        title: const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        actions: [
          // --- NUEVO BOTÓN DE EDITAR ---
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2D3142)),
            tooltip: 'Editar Transacción',
            onPressed: () async {
              // Aquí navegaremos a la pantalla de Crear/Editar, pasándole los datos actuales
               final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CrearTransaccionScreen(
                    transaccionAEditar: transaccion, // Le pasamos la transacción
                  ),
                ),
              );

              // Si se guardaron los cambios correctamente, cerramos este detalle 
              // para que el Dashboard se recargue y muestre los datos frescos.
              if (resultado == true && context.mounted) {
                Navigator.pop(context, true); 
              }
            },
          ),
          
          // --- BOTÓN DE ELIMINAR (Se mantiene igual) ---
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Anular Transacción',
            onPressed: () async {
              bool confirmar = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('¿Anular Transacción?'),
                  content: const Text('Esta transacción se anulará y los saldos se recalcularán automáticamente. ¿Deseas continuar?'),
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
                final service = FinanceService();
                bool exito = await service.eliminarTransaccion(transaccion.idTransaccion);

                if (exito && context.mounted) {
                  // --- SNACKBAR PREMIUM DE ÉXITO ---
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating, 
                      backgroundColor: const Color(0xFF11998E), 
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
                                Text('¡Operación Exitosa!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('La transacción ha sido anulada.', style: TextStyle(fontSize: 13, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  
                  Navigator.pop(context, true); 
                  
                } else if (context.mounted) {
                  // --- SNACKBAR PREMIUM DE ERROR ---
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
                      elevation: 10,
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ocurrió un problema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('No se pudo anular la transacción.', style: TextStyle(fontSize: 13, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: bgGradient[0].withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    transaccion.tipoTransaccionNombre?.toUpperCase() ?? 'TRANSACCIÓN',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${esIngreso ? '+' : '-'}$simboloMoneda ${transaccion.monto.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                if (transaccion.concepto != null && transaccion.concepto!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '"${transaccion.concepto}"',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text('Detalles de la operación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  // --- AQUÍ USAMOS LOS NUEVOS DATOS ---
                  _buildDetailRow(
                    Icons.category_outlined, 
                    'Categoría', 
                    '${transaccion.categoriaPadreNombre ?? "General"}  >  ${transaccion.subcategoriaNombre ?? "Sin categoría"}'
                  ),
                  const Divider(height: 32, color: Color(0xFFF0F0F0)),
                  
                  // Fecha en formato completo
                  _buildDetailRow(Icons.calendar_today_outlined, 'Fecha y Hora', fechaFinal),
                  const Divider(height: 32, color: Color(0xFFF0F0F0)),
                  
                  // Método de pago con su nombre
                  _buildDetailRow(Icons.account_balance_wallet_outlined, 'Método de Pago', transaccion.metodoPagoNombre ?? 'No especificado'),
                  
                  if (transaccion.personaId != null) ...[
                    const Divider(height: 32, color: Color(0xFFF0F0F0)),
                    // Nombre de la persona vinculada
                    _buildDetailRow(Icons.person_outline, 'Persona vinculada', transaccion.personaNombre ?? 'Desconocido'),
                  ],
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF2D3142), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Color(0xFF2D3142), fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}