import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finanzas/cuenta_corriente.dart';
import '../../services/finance_service.dart';
import '../movimiento_cuenta/movimiento_cuenta_screen.dart'; 
import 'crear_cuenta_corriente_screen.dart';

class CuentasScreen extends StatefulWidget {
  const CuentasScreen({super.key});

  @override
  State<CuentasScreen> createState() => _CuentasScreenState();
}

class _CuentasScreenState extends State<CuentasScreen> {
  final FinanceService _service = FinanceService();
  late Future<List<CuentaCorriente>> _cuentasFuture;

  // ¡MAGIA DE COLORES! Una lista de degradados premium
  final List<List<Color>> _paletaGradients = [
    [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Morado vibrante
    [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Esmeralda/Neón
    [const Color(0xFFFC4A1A), const Color(0xFFF7B733)], // Fuego/Naranja
    [const Color(0xFF0052D4), const Color(0xFF6FB1FC)], // Azul Océano
  ];

  @override
  void initState() {
    super.initState();
    _cuentasFuture = _service.getCuentasCorrientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Un gris ultra claro y elegante
      appBar: AppBar(
        title: const Text('Mis Cuentas', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent, // Barra transparente
        foregroundColor: const Color(0xFF2D3142), // Texto oscuro azulado
        elevation: 0,
        centerTitle: false, // Alineado a la izquierda se ve más moderno
      ),
      body: FutureBuilder<List<CuentaCorriente>>(
        future: _cuentasFuture,
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Color(0xFFB0BEC5)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Aún no tienes cuentas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  const Text('Crea tu primera cuenta para empezar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final cuentas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100, left: 20, right: 20), // Más margen lateral
            itemCount: cuentas.length,
            itemBuilder: (context, index) {
              final cuenta = cuentas[index];
              final fecha = cuenta.fechaRegistro != null 
                  ? DateFormat('dd/MM/yyyy').format(cuenta.fechaRegistro!)
                  : '';

              // Seleccionamos un color diferente basado en la posición de la tarjeta
              final colores = _paletaGradients[index % _paletaGradients.length];

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colores,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24), // Bordes más redondeados
                  boxShadow: [
                    BoxShadow(
                      color: colores[0].withOpacity(0.4), // La sombra coincide con el color de la tarjeta
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MovimientosCuentaScreen(cuenta: cuenta)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    cuenta.personaNombre ?? 'Desconocida',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text('MONEDA', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                cuenta.monedaSimbolo ?? "?",
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                fecha,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
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
          gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]), // Botón flotante degradado
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent, // El fondo lo da el Container de arriba
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva Cuenta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () async {
            final resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CrearCuentaScreen()));

            if (resultado == true) {
              // LA CURA: Usar llaves {} en lugar de =>
              setState(() {
                _cuentasFuture = _service.getCuentasCorrientes();
              });
              
       
            }
          },
        ),
      ),
    );
  }
}