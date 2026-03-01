import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart';
import 'dart:math' as math; 

import '../services/finance_service.dart';
import '../services/catalogo_service.dart';

import '../models/catalogos/moneda.dart';
import '../models/catalogos/tipo_transaccion.dart';
import '../models/catalogos/metodo_pago.dart';
import '../models/catalogos/categoria.dart';
import '../models/catalogos/subcategoria.dart';
import '../models/persona.dart';
import '../models/finanzas/transaccion.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();

  bool _isLoading = true;

  // Listas de datos
  List<Transaccion> _todasLasTransacciones = [];
  List<Moneda> _monedas = [];
  List<TipoTransaccion> _tiposTransaccion = [];
  List<MetodoPago> _metodosPago = [];
  List<Categoria> _categorias = [];
  List<SubCategoria> _subcategorias = [];
  List<Persona> _personas = [];

  // Variables de FILTRO seleccionadas
  int? _filtroMoneda;
  int? _filtroTipo;
  int? _filtroMetodo;
  int? _filtroPersona;
  int? _filtroCategoria;
  int? _filtroSubcategoria;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final respuestas = await Future.wait([
        _financeService.getTransacciones(),
        _catalogoService.getMonedas(),
        _catalogoService.getTiposTransaccion(),
        _catalogoService.getMetodosPago(),
        _catalogoService.getCategorias(),
        _catalogoService.getSubCategorias(),
        _financeService.getPersonas(),
      ]);

      setState(() {
        _todasLasTransacciones = respuestas[0] as List<Transaccion>;
        _monedas = respuestas[1] as List<Moneda>;
        _tiposTransaccion = respuestas[2] as List<TipoTransaccion>;
        _metodosPago = respuestas[3] as List<MetodoPago>;
        _categorias = respuestas[4] as List<Categoria>;
        _subcategorias = respuestas[5] as List<SubCategoria>;
        _personas = respuestas[6] as List<Persona>;

        if (_monedas.isNotEmpty) {
          _filtroMoneda = _monedas.first.idMoneda; 
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMenuFiltros() {
    int? tempMoneda = _filtroMoneda;
    int? tempTipo = _filtroTipo;
    int? tempCategoria = _filtroCategoria;
    int? tempSubcategoria = _filtroSubcategoria;
    int? tempPersona = _filtroPersona;
    DateTime? tempDesde = _fechaDesde;
    DateTime? tempHasta = _fechaHasta;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Future<void> seleccionarFechas() async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: tempDesde != null && tempHasta != null
                    ? DateTimeRange(start: tempDesde!, end: tempHasta!)
                    : null,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF4A00E0))),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setModalState(() {
                  tempDesde = picked.start;
                  tempHasta = picked.end;
                });
              }
            }

            List<SubCategoria> subcategoriasTempList = tempCategoria == null 
                ? [] 
                : _subcategorias.where((s) => s.categoriaId == tempCategoria).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filtros Avanzados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fechas Estilizado
                    InkWell(
                      onTap: seleccionarFechas,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, color: Color(0xFF4A00E0)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rango de Fechas', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  tempDesde != null && tempHasta != null
                                      ? '${DateFormat('dd MMM').format(tempDesde!)} - ${DateFormat('dd MMM').format(tempHasta!)}'
                                      : 'Seleccionar (Opcional)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tempDesde != null ? const Color(0xFF2D3142) : Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildDropdown(label: 'Moneda', value: tempMoneda, items: _monedas.map((m) => DropdownMenuItem(value: m.idMoneda, child: Text(m.simbolo))).toList(), onChanged: (val) => setModalState(() => tempMoneda = val))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown(label: 'Tipo', value: tempTipo, items: [const DropdownMenuItem(value: null, child: Text('Todos')), ..._tiposTransaccion.map((t) => DropdownMenuItem(value: t.idTipoTransaccion, child: Text(t.nombre)))], onChanged: (val) => setModalState(() => tempTipo = val))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildDropdown(
                      label: 'Categoría Principal',
                      value: tempCategoria,
                      items: [const DropdownMenuItem(value: null, child: Text('Todas')), ..._categorias.map((c) => DropdownMenuItem(value: c.idCategoria, child: Text(c.nombre)))],
                      onChanged: (val) => setModalState(() { tempCategoria = val; tempSubcategoria = null; }),
                    ),
                    const SizedBox(height: 16),

                    _buildDropdown(
                      label: 'Subcategoría',
                      value: tempSubcategoria,
                      hint: tempCategoria == null ? 'Elige categoría' : 'Todas',
                      items: [if (tempCategoria != null) const DropdownMenuItem(value: null, child: Text('Todas')), ...subcategoriasTempList.map((s) => DropdownMenuItem(value: s.idSubcategoria, child: Text(s.nombre)))],
                      onChanged: tempCategoria == null ? null : (val) => setModalState(() => tempSubcategoria = val),
                    ),
                    const SizedBox(height: 16),

                    _buildDropdown(
                      label: 'Persona Vinculada',
                      value: tempPersona,
                      items: [const DropdownMenuItem(value: null, child: Text('Todas')), ..._personas.map((p) => DropdownMenuItem(value: p.idPersona, child: Text(p.nombre)))],
                      onChanged: (val) => setModalState(() => tempPersona = val),
                    ),
                    const SizedBox(height: 32),

                    // Botón Aplicar
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () {
                          setState(() {
                            _filtroMoneda = tempMoneda; _filtroTipo = tempTipo; _filtroCategoria = tempCategoria;
                            _filtroSubcategoria = tempSubcategoria; _filtroPersona = tempPersona;
                            _fechaDesde = tempDesde; _fechaHasta = tempHasta;
                          });
                          Navigator.pop(context); 
                        },
                        child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  // Widget helper para dropdowns limpios
  Widget _buildDropdown({required String label, required dynamic value, required List<DropdownMenuItem<dynamic>> items, required Function(dynamic)? onChanged, String? hint}) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      value: value,
      hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey.shade400)) : null,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142), fontSize: 15),
    );
  }

  List<Transaccion> get _transaccionesFiltradas {
    return _todasLasTransacciones.where((tx) {
      if (_filtroMoneda != null && tx.monedaId != _filtroMoneda) return false;
      if (_filtroTipo != null && tx.tipoTransaccionId != _filtroTipo) return false;
      if (_filtroPersona != null && tx.personaId != _filtroPersona) return false;
      if (_filtroSubcategoria != null && tx.subcategoriaId != _filtroSubcategoria) return false;
      if (_filtroCategoria != null && _filtroSubcategoria == null) {
        final subcat = _subcategorias.firstWhere((s) => s.idSubcategoria == tx.subcategoriaId, orElse: () => SubCategoria(idSubcategoria: -1, nombre: '', categoriaId: -1));
        if (subcat.categoriaId != _filtroCategoria) return false;
      }
      if (tx.fechaRegistro != null) {
        if (_fechaDesde != null && tx.fechaRegistro!.isBefore(_fechaDesde!)) return false;
        if (_fechaHasta != null && tx.fechaRegistro!.isAfter(_fechaHasta!.add(const Duration(days: 1)))) return false;
      }
      return true;
    }).toList();
  }

  double get _totalIngresos => _transaccionesFiltradas.where((t) => (t.tipoTransaccionNombre ?? '').toLowerCase().contains('ingreso') || (t.tipoTransaccionNombre ?? '').toLowerCase().contains('entrada')).fold(0.0, (sum, item) => sum + item.monto);
  double get _totalEgresos => _transaccionesFiltradas.where((t) => (t.tipoTransaccionNombre ?? '').toLowerCase().contains('egreso') || (t.tipoTransaccionNombre ?? '').toLowerCase().contains('salida')).fold(0.0, (sum, item) => sum + item.monto);

  @override
  Widget build(BuildContext context) {
    final double maximoY = math.max(_totalIngresos, _totalEgresos) * 1.2;
    final double techoGrafico = maximoY == 0 ? 100 : maximoY;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Análisis', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3142)),
            tooltip: 'Limpiar Filtros',
            onPressed: () {
              setState(() {
                _filtroTipo = null; _filtroPersona = null; _filtroCategoria = null;
                _filtroSubcategoria = null; _fechaDesde = null; _fechaHasta = null;
              });
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : Column(
              children: [
                // --- BOTÓN DE FILTROS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: InkWell(
                    onTap: _mostrarMenuFiltros,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune, color: Color(0xFF4A00E0), size: 20),
                          SizedBox(width: 8),
                          Text('Ajustar Filtros', style: TextStyle(color: Color(0xFF4A00E0), fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // --- RESUMEN RÁPIDO ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF38EF7D).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('INGRESOS', style: TextStyle(color: Color(0xFF11998E), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text('+ ${_totalIngresos.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF11998E), fontSize: 20, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFFF5252).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EGRESOS', style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text('- ${_totalEgresos.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 20, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- EL GRÁFICO DE BARRAS ---
                SizedBox(
                  height: 200, 
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: techoGrafico,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => const Color(0xFF2D3142),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem('${rod.toY.toStringAsFixed(2)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    value.toInt() == 0 ? 'Ingresos' : 'Gastos',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: value.toInt() == 0 ? const Color(0xFF11998E) : const Color(0xFFFF5252)),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) => Text(value == techoGrafico ? '' : value.toInt().toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: techoGrafico / 5, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _totalIngresos, color: const Color(0xFF38EF7D), width: 50, borderRadius: BorderRadius.circular(8))]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _totalEgresos, color: const Color(0xFFFF5252), width: 50, borderRadius: BorderRadius.circular(8))]),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- TÍTULO DE LA LISTA ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Desglose', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
                  ),
                ),
                const SizedBox(height: 16),

                // --- LA LISTA DINÁMICA ---
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                    ),
                    child: _transaccionesFiltradas.isEmpty
                        ? const Center(child: Text('No hay datos para estos filtros.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 24, bottom: 100, left: 16, right: 16),
                            itemCount: _transaccionesFiltradas.length,
                            itemBuilder: (context, index) {
                              final tx = _transaccionesFiltradas[index];
                              final esIngreso = (tx.tipoTransaccionNombre ?? '').toLowerCase().contains('ingreso') || (tx.tipoTransaccionNombre ?? '').toLowerCase().contains('entrada');
                              final fecha = tx.fechaRegistro != null ? DateFormat('dd MMM, HH:mm').format(tx.fechaRegistro!) : '';
                              final monedaActual = _monedas.firstWhere((m) => m.idMoneda == _filtroMoneda, orElse: () => _monedas.isNotEmpty ? _monedas.first : Moneda(idMoneda: 0, nombre: '', simbolo: ''));

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: esIngreso ? const Color(0xFF38EF7D).withOpacity(0.15) : const Color(0xFFFF5252).withOpacity(0.15), shape: BoxShape.circle),
                                      child: Icon(esIngreso ? Icons.arrow_downward : Icons.arrow_upward, color: esIngreso ? const Color(0xFF11998E) : const Color(0xFFFF5252), size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tx.subcategoriaNombre ?? 'Transacción', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                                          const SizedBox(height: 4),
                                          Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${esIngreso ? '+' : '-'}${monedaActual.simbolo} ${tx.monto.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: esIngreso ? const Color(0xFF11998E) : const Color(0xFFFF5252)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}