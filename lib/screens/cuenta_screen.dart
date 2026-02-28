import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finanzas/cuenta_corriente.dart';
import '../services/finance_service.dart';
import 'movimiento_cuenta_screen.dart'; // Importamos la pantalla de detalles
import 'crear_cuenta_corriente_screen.dart';
class CuentasScreen extends StatefulWidget {
  const CuentasScreen({super.key});

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<CuentaCorriente>> _cuentasFuture;

  @override
  void initState() {
    super.initState();
    _cuentasFuture = _service.getCuentasCorrientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas Corrientes'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<CuentaCorriente>>(
        future: _cuentasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes cuentas corrientes activas.'));
          }

          final cuentas = snapshot.data!;

          return ListView.builder(
            itemCount: cuentas.length,
            itemBuilder: (context, index) {
              final cuenta = cuentas[index];
              final fecha = cuenta.fechaRegistro != null 
                  ? DateFormat('dd/MM/yyyy').format(cuenta.fechaRegistro!)
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.account_balance, color: Colors.white),
                  ),
                  title: Text(
                    cuenta.personaNombre ?? 'Persona Desconocida',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Moneda de la cuenta: ${cuenta.monedaSimbolo ?? "?"}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  
                  // ¡LA NAVEGACIÓN! Al tocar la cuenta, abrimos sus movimientos
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovimientosCuentaScreen(cuenta: cuenta),
                      ),
                    );
                  },
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
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearCuentaScreen()),
          );
          // Si devuelve true, recargamos la lista
          if (resultado == true) {
            setState(() {
              _cuentasFuture = _service.getCuentasCorrientes();
            });
          }
        },
        child: const Icon(Icons.add_card),
      ),
      
    );
  }
}