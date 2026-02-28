import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importante para formatear fecha y hora
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import 'login_screen.dart';
import 'crear_transaccion_screen.dart'; // <--- Añade esto arriba

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceService _financeService = FinanceService();
  
  // Cambiamos a DashboardData para recibir tanto el saldo como la lista
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    // Disparamos la petición unificada al backend
    _dashboardFuture = _financeService.getDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Financiero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      // Actualizamos el FutureBuilder para que use DashboardData
      body: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          // 1. Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          // 2. Estado de error
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ocurrió un error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } 
          
          // 3. Estado sin transacciones
          else if (!snapshot.hasData || snapshot.data!.transacciones.isEmpty) {
            return const Center(
              child: Text('Aún no tienes transacciones registradas.'),
            );
          }

          // 4. Estado con datos exitosos
          final datos = snapshot.data!;
          final transacciones = datos.transacciones;
          final saldoGlobal = datos.saldoGlobal; // Dato calculado por Django

          return Column(
            children: [
              // --- TARJETA DE SALDO GLOBAL ---
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  // Verde si el saldo es positivo, rojo si es negativo
                  gradient: LinearGradient(
                    colors: saldoGlobal >= 0 
                        ? [Colors.green.shade400, Colors.green.shade800]
                        : [Colors.red.shade400, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Saldo Global',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bs. ${saldoGlobal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // --- TÍTULO DE LA LISTA ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Movimientos Recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // --- LISTA DE TRANSACCIONES ---
              Expanded(
                child: ListView.builder(
                  itemCount: transacciones.length,
                  itemBuilder: (context, index) {
                    final transaccion = transacciones[index];
                    
                    // Formatear la fecha para incluir la hora
                    final fechaFormateada = transaccion.fechaRegistro != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(transaccion.fechaRegistro!)
                        : 'Sin fecha';

                    // Lógica para determinar colores y signos
                    final nombreTipo = transaccion.tipoTransaccionNombre?.toLowerCase() ?? '';
                    final esEntrada = nombreTipo.contains('entrada') || nombreTipo.contains('ingreso');

                    final colorTransaccion = esEntrada ? Colors.green : Colors.red;
                    final iconoTransaccion = esEntrada ? Icons.arrow_upward : Icons.arrow_downward;
                    final signoMonto = esEntrada ? '+' : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorTransaccion.withOpacity(0.15),
                          child: Icon(iconoTransaccion, color: colorTransaccion),
                        ),
                        title: Text(
                          transaccion.subcategoriaNombre ?? 'Categoría ${transaccion.subcategoriaId}', 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(fechaFormateada),
                        trailing: Text(
                          '$signoMonto Bs. ${transaccion.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: colorTransaccion,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () async {
          // Navegamos a la pantalla de crear y ESPERAMOS el resultado
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearTransaccionScreen()),
          );

          // Si el resultado es true (significa que se guardó exitosamente),
          // recargamos el Dashboard llamando a setState
          if (resultado == true) {
            setState(() {
              _dashboardFuture = _financeService.getDashboardData();
            });
            
            // Mostramos un mensajito de éxito
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Transacción registrada!'), 
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}