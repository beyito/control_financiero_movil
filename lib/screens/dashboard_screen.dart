import 'package:control_financiero/services/catalogo_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/finance_service.dart';
import '../models/catalogos/moneda.dart'; 
import '../models/finanzas/transaccion.dart'; 
import 'transaccion/crear_transaccion_screen.dart'; 
import '../services/auth_service.dart';
import 'usuario/login_screen.dart'; 
import 'transaccion/detalle_transaccion_screen.dart'; 
import 'usuario/perfil_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  bool _isLoading = true;
  List<Moneda> _monedas = [];
  List<Transaccion> _todasLasTransacciones = [];
  int _indiceMonedaActual = 0;

  // Paleta de degradados para las diferentes monedas
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Verde (Ej: Dólares)
    [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Morado (Ej: Bolivianos)
    [const Color(0xFFFC4A1A), const Color(0xFFF7B733)], // Naranja
    [const Color(0xFF0052D4), const Color(0xFF6FB1FC)], // Azul
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final respuestas = await Future.wait([
        _catalogoService.getMonedas(),
        _financeService.getTransacciones(),
      ]);

      setState(() {
        _monedas = respuestas[0] as List<Moneda>;
        _todasLasTransacciones = respuestas[1] as List<Transaccion>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Transaccion> get _transaccionesFiltradas {
    if (_monedas.isEmpty) return [];
    final monedaActual = _monedas[_indiceMonedaActual];
    return _todasLasTransacciones.where((t) => t.monedaId == monedaActual.idMoneda).toList();
  }

  double get _totalEntradas {
    return _transaccionesFiltradas
        .where((t) => (t.tipoTransaccionNombre ?? '').toLowerCase().contains('ingreso') || 
                      (t.tipoTransaccionNombre ?? '').toLowerCase().contains('entrada'))
        .fold(0.0, (sum, item) => sum + item.monto);
  }

  double get _totalSalidas {
    return _transaccionesFiltradas
        .where((t) => (t.tipoTransaccionNombre ?? '').toLowerCase().contains('egreso') || 
                      (t.tipoTransaccionNombre ?? '').toLowerCase().contains('salida'))
        .fold(0.0, (sum, item) => sum + item.monto);
  }

  double get _saldoGlobal => _totalEntradas - _totalSalidas;

  final AuthService _authService = AuthService();

  void _onMenuSelected(BuildContext context, int item) async {
    if (item == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
    } else if (item == 1) {
      bool confirmar = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Cerrar Sesión?'),
          content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false;

      if (confirmar && context.mounted) {
        await _authService.logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo ultra limpio
      appBar: AppBar(
        title: const Text('Mi Resumen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2D3142)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (item) => _onMenuSelected(context, item),
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Row(children: [Icon(Icons.person_outline, color: Color(0xFF2D3142)), SizedBox(width: 12), Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.w600))]),
              ),
              const PopupMenuDivider(), 
              const PopupMenuItem<int>(
                value: 1,
                child: Row(children: [Icon(Icons.exit_to_app, color: Colors.redAccent), SizedBox(width: 12), Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600))]),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF11998E)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CARRUSEL DE TARJETAS ---
                SizedBox(
                  height: 220, // Altura de la tarjeta
                  child: _monedas.isEmpty
                      ? const Center(child: Text('No hay monedas registradas', style: TextStyle(color: Colors.grey)))
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _indiceMonedaActual = index),
                          itemCount: _monedas.length,
                          itemBuilder: (context, index) {
                            final moneda = _monedas[index];
                            final gradient = _cardGradients[index % _cardGradients.length];
                            return _construirTarjetaSaldo(moneda, gradient);
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // --- TÍTULO DE LISTA ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Recientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
                      if (_monedas.isNotEmpty)
                        Text(
                          'En ${_monedas[_indiceMonedaActual].nombre}', 
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- LISTA DE TRANSACCIONES ---
                Expanded(
                  child: _transaccionesFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No hay actividad aún', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                          itemCount: _transaccionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final tx = _transaccionesFiltradas[index];
                            final esIngreso = (tx.tipoTransaccionNombre ?? '').toLowerCase().contains('ingreso') || 
                                              (tx.tipoTransaccionNombre ?? '').toLowerCase().contains('entrada');
                            final fecha = tx.fechaRegistro != null ? DateFormat('dd MMM, HH:mm').format(tx.fechaRegistro!) : '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetalleTransaccionScreen(
                                        transaccion: tx,
                                        simboloMoneda: _monedas[_indiceMonedaActual].simbolo,
                                      ),
                                    ),
                                  );
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: esIngreso ? const Color(0xFF38EF7D).withOpacity(0.15) : const Color(0xFFFF5252).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(esIngreso ? Icons.arrow_downward : Icons.arrow_upward, 
                                      color: esIngreso ? const Color(0xFF11998E) : const Color(0xFFFF5252), size: 22),
                                ),
                                title: Text(tx.subcategoriaNombre ?? 'Transacción', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                ),
                                trailing: Text(
                                  '${esIngreso ? '+' : '-'}${_monedas[_indiceMonedaActual].simbolo} ${tx.monto.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 16,
                                    color: esIngreso ? const Color(0xFF11998E) : const Color(0xFFFF5252)
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF11998E).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () async {
            final resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CrearTransaccionScreen()));
            if (resultado == true) _cargarDatos(); 
          },
        ),
      ),
    );
  }

  // --- DISEÑO PREMIUM DE LA TARJETA DE SALDO ---
  Widget _construirTarjetaSaldo(Moneda moneda, List<Color> gradientColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SALDO TOTAL', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(moneda.simbolo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${moneda.simbolo} ${_saldoGlobal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingresos', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${moneda.simbolo} ${_totalEntradas.toStringAsFixed(2)}', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Egresos', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${moneda.simbolo} ${_totalSalidas.toStringAsFixed(2)}', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}