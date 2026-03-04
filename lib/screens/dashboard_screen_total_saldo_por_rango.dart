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
import 'dictado_screen.dart';

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
  List<Transaccion> _transaccionesFiltradas = []; 
  int _indiceMonedaActual = 0;

  // --- VARIABLES PARA EL FILTRO ---
  String _filtroTiempo = 'Esta Semana';
  final List<String> _opcionesFiltro = ['Esta Semana', 'Este Mes', 'Mes Anterior', 'Todas'];

  // Paleta de degradados
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF11998E), const Color(0xFF38EF7D)], 
    [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], 
    [const Color(0xFFFC4A1A), const Color(0xFFF7B733)], 
    [const Color(0xFF0052D4), const Color(0xFF6FB1FC)], 
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- LÓGICA DE FECHAS PARA EL BACKEND ---
  Map<String, String?> _obtenerRangoFechas() {
    final ahora = DateTime.now();
    DateFormat formato = DateFormat('yyyy-MM-dd'); 

    if (_filtroTiempo == 'Esta Semana') {
      final inicio = ahora.subtract(const Duration(days: 7));
      return {'inicio': formato.format(inicio), 'fin': formato.format(ahora)};
    } else if (_filtroTiempo == 'Este Mes') {
      final inicio = DateTime(ahora.year, ahora.month, 1);
      final fin = DateTime(ahora.year, ahora.month + 1, 0); 
      return {'inicio': formato.format(inicio), 'fin': formato.format(fin)};
    } else if (_filtroTiempo == 'Mes Anterior') {
      int mesAnt = ahora.month == 1 ? 12 : ahora.month - 1;
      int anioAnt = ahora.month == 1 ? ahora.year - 1 : ahora.year;
      final inicio = DateTime(anioAnt, mesAnt, 1);
      final fin = DateTime(anioAnt, mesAnt + 1, 0);
      return {'inicio': formato.format(inicio), 'fin': formato.format(fin)};
    }
    return {'inicio': null, 'fin': null}; 
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final fechas = _obtenerRangoFechas();

      final respuestas = await Future.wait([
        _catalogoService.getMonedas(),
        _financeService.getTransacciones(fechaInicio: fechas['inicio'], fechaFin: fechas['fin']),
      ]);

      setState(() {
        _monedas = respuestas[0] as List<Moneda>;
        _transaccionesFiltradas = respuestas[1] as List<Transaccion>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- CÁLCULOS DEL PERIODO (Filtrados por Moneda Actual) ---
  List<Transaccion> get _transaccionesMonedaActual {
    if (_monedas.isEmpty) return [];
    return _transaccionesFiltradas.where((t) => t.monedaId == _monedas[_indiceMonedaActual].idMoneda).toList();
  }

  double get _totalEntradas {
    return _transaccionesMonedaActual
        .where((t) => (t.tipoTransaccionNombre ?? '').toLowerCase().contains('ingreso') || 
                      (t.tipoTransaccionNombre ?? '').toLowerCase().contains('entrada'))
        .fold(0.0, (sum, item) => sum + item.monto);
  }

  double get _totalSalidas {
    return _transaccionesMonedaActual
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
    // Variable auxiliar para hacer el código de la lista más limpio
    final listaMostrar = _transaccionesMonedaActual; 

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          : RefreshIndicator(
              onRefresh: _cargarDatos, 
              color: const Color(0xFF11998E), 
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(), 
                padding: const EdgeInsets.only(bottom: 100), 
                children: [
                  
                  // --- CARRUSEL DE TARJETAS ---
                  SizedBox(
                    height: 220,
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

                  // --- TÍTULO DE LISTA CON FILTRO ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filtroTiempo,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2D3142)),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                            items: _opcionesFiltro.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null && newValue != _filtroTiempo) {
                                setState(() {
                                  _filtroTiempo = newValue;
                                });
                                _cargarDatos(); 
                              }
                            },
                          ),
                        ),
                        
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
                  if (listaMostrar.isEmpty)
                    SizedBox(
                      height: 200, 
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No hay actividad en este periodo', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: listaMostrar.length, // <-- BUG CORREGIDO AQUÍ
                      itemBuilder: (context, index) {
                        final tx = listaMostrar[index]; // <-- BUG CORREGIDO AQUÍ
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
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnMic", 
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: () async {
              final resultado = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const DictadoScreen())
              );
              if (resultado == true) _cargarDatos(); 
            },
            child: const Icon(Icons.mic, color: Color(0xFF11998E), size: 28),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: const Color(0xFF11998E).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: FloatingActionButton(
              heroTag: "btnAdd",
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const CrearTransaccionScreen())
                );
                if (resultado == true) _cargarDatos(); 
              },
            ),
          ),
        ],
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
              // Cambié "SALDO TOTAL" a "BALANCE DEL PERIODO" para que tenga más sentido
              Text('BALANCE DEL PERIODO', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
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
                  // Agregamos el filtro al texto para darle contexto al usuario
                  Text('Ingresos (${_filtroTiempo.toLowerCase()})', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
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
                  // Agregamos el filtro al texto
                  Text('Egresos (${_filtroTiempo.toLowerCase()})', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
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