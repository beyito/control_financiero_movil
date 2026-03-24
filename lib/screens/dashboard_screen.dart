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
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();
  final PageController _pageController = PageController(viewportFraction: 0.92);
  
  // --- VARIABLES DE PAGINACIÓN ---
  final ScrollController _scrollController = ScrollController();
  int _paginaActual = 1;
  bool _hayMasPaginas = true;
  bool _isCargandoMas = false; 

  bool _esPrimeraCarga = true;
  bool _isLoading = true; // Controla la carga GIGANTE inicial
  bool _isFetchingTransacciones = false; // Controla solo la carga de la lista al cambiar filtros
  
  List<Moneda> _monedas = [];
  List<Transaccion> _transaccionesFiltradas = []; 
  Map<int, double> _saldosGlobales = {}; 
  int _indiceMonedaActual = 0;

  // --- TOTALES GLOBALES (Vienen del Backend) ---
  double _totalIngresosGlobal = 0.0;
  double _totalEgresosGlobal = 0.0;

  // --- VARIABLES PARA EL FILTRO ---
  String _filtroTiempo = 'Hoy'; 
  final List<String> _opcionesFiltro = ['Hoy', 'Esta Semana', 'Este Mes', 'Mes Anterior', 'Todas'];

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

    // --- ESCUCHADOR DE SCROLL INFINITO ---
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _cargarMasTransacciones();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE FECHAS PARA EL BACKEND ---
  Map<String, String?> _obtenerRangoFechas() {
    final ahora = DateTime.now();
    DateFormat formato = DateFormat('yyyy-MM-dd'); 

    if (_filtroTiempo == 'Hoy') {
      return {'inicio': formato.format(ahora), 'fin': formato.format(ahora)};
    } else if (_filtroTiempo == 'Esta Semana') {
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

  // --- DETECCIÓN DE MONEDA LOCAL ---
  String _obtenerSimboloMonedaLocal() {
    try {
      final String localeName = Platform.localeName; 
      final List<String> partes = localeName.split('_');
      final String codigoIdioma = partes.first.toLowerCase(); 
      final String codigoPais = partes.last.toUpperCase();    

      switch (codigoPais) {
        case 'BO': return 'Bs'; 
        case 'ES': return '€';  
        case 'US': return codigoIdioma == 'es' ? 'Bs' : '\$'; 
        default: return 'Bs';   
      }
    } catch (e) {
      return 'Bs'; 
    }
  }

  // --- CARGA INICIAL Y REFRESH ---
  Future<void> _cargarDatos() async {
    setState(() {
      // MAGIA AQUÍ: Solo hacemos loading gigante si no hay monedas. 
      // Si ya hay monedas (ej. giramos tarjeta), solo mostramos loading en la lista abajo.
      if (_monedas.isEmpty) {
        _isLoading = true;
      } else {
        _isFetchingTransacciones = true; 
      }
      _paginaActual = 1;
      _hayMasPaginas = true;
    });

    try {
      final fechas = _obtenerRangoFechas();

      if (_monedas.isEmpty) {
        _monedas = await _catalogoService.getMonedas();
        if (_monedas.isNotEmpty) {
          final simboloLocal = _obtenerSimboloMonedaLocal(); 
          final int indexEncontrado = _monedas.indexWhere((m) => m.simbolo.contains(simboloLocal) || m.nombre.contains(simboloLocal));

          if (indexEncontrado != -1 && indexEncontrado != 0) {
            _indiceMonedaActual = indexEncontrado;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(indexEncontrado);
              }
            });
          }
          _esPrimeraCarga = false; 
        }
      }

      if (_monedas.isEmpty) {
         if (mounted) setState(() { _isLoading = false; _isFetchingTransacciones = false; });
         return;
      }

      final respuestas = await Future.wait([
        _financeService.getTransacciones(
          fechaInicio: fechas['inicio'], 
          fechaFin: fechas['fin'], 
          page: _paginaActual,
          monedaId: _monedas[_indiceMonedaActual].idMoneda, 
        ),
        _financeService.getSaldosGlobales(), 
      ]);

      if (!mounted) return;

      setState(() {
        final paginatedData = respuestas[0] as PaginatedTransacciones;
        _transaccionesFiltradas = paginatedData.transacciones;
        _hayMasPaginas = paginatedData.nextUrl != null;

        _totalIngresosGlobal = paginatedData.totalIngresos;
        _totalEgresosGlobal = paginatedData.totalEgresos;

        _saldosGlobales = respuestas[1] as Map<int, double>; 
        
        if (_indiceMonedaActual >= _monedas.length) {
          _indiceMonedaActual = _monedas.isNotEmpty ? _monedas.length - 1 : 0;
        }

        _isLoading = false; 
        _isFetchingTransacciones = false; // Ocultamos el spinner de la lista
      });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _isFetchingTransacciones = false; });
    }
  }

  // --- CARGAR PÁGINAS SIGUIENTES (SCROLL INFINITO) ---
  Future<void> _cargarMasTransacciones() async {
    if (_isCargandoMas || !_hayMasPaginas || _monedas.isEmpty) return;

    setState(() => _isCargandoMas = true);
    _paginaActual++;

    try {
      final fechas = _obtenerRangoFechas();
      final nuevasTransacciones = await _financeService.getTransacciones(
        fechaInicio: fechas['inicio'], 
        fechaFin: fechas['fin'], 
        page: _paginaActual,
        monedaId: _monedas[_indiceMonedaActual].idMoneda,
      );

      if (!mounted) return;

      setState(() {
        _transaccionesFiltradas.addAll(nuevasTransacciones.transacciones);
        _hayMasPaginas = nuevasTransacciones.nextUrl != null;
        _isCargandoMas = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isCargandoMas = false);
    }
  }

  // --- CÁLCULOS (Usan los datos directos del Backend) ---
  double get _totalEntradas => _totalIngresosGlobal;
  double get _totalSalidas => _totalEgresosGlobal;

  double get _saldoGlobal {
    if (_monedas.isEmpty) return 0.0;
    final idMoneda = _monedas[_indiceMonedaActual].idMoneda;
    return _saldosGlobales[idMoneda] ?? 0.0; 
  }

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
                controller: _scrollController,
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
                            onPageChanged: (index) {
                              if (_indiceMonedaActual != index) {
                                setState(() => _indiceMonedaActual = index);
                                _cargarDatos(); 
                              }
                            },
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

                  // --- LISTA DE TRANSACCIONES O SPINNER SECUNDARIO ---
                  if (_isFetchingTransacciones)
                    const SizedBox(
                      height: 200, 
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF11998E))
                      ),
                    )
                  else if (_transaccionesFiltradas.isEmpty)
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
                            onTap: () async {
                              final resultado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalleTransaccionScreen(
                                    transaccion: tx,
                                    simboloMoneda: _monedas[_indiceMonedaActual].simbolo,
                                  ),
                                ),
                              );

                              if (resultado == true) {
                                _cargarDatos();
                              }
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
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${esIngreso ? '+' : '-'}${_monedas[_indiceMonedaActual].simbolo} ${tx.monto.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 16,
                                    color: esIngreso ? const Color(0xFF11998E) : const Color(0xFFFF5252)
                                  ),
                                ),
                                if (tx.personaNombre != null && tx.personaNombre!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        tx.personaNombre!,
                                        style: const TextStyle(
                                          color: Colors.grey, 
                                          fontSize: 11, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // --- SPINNER DE CARGA AL FINAL ---
                  if (_isCargandoMas)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF11998E)),
                      ),
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
                int? idMonedaActual;
                if (_monedas.isNotEmpty) {
                  idMonedaActual = _monedas[_indiceMonedaActual].idMoneda;
                }

                final resultado = await Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => CrearTransaccionScreen(
                      idMonedaPredeterminada: idMonedaActual, 
                    )
                  )
                );
                if (resultado == true) _cargarDatos(); 
              },
            ),
          ),
        ],
      ),
    );
  }

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