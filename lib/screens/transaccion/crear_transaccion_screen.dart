import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/finance_service.dart';
import '../../services/catalogo_service.dart';

import '../../models/catalogos/categoria.dart'; 
import '../../models/catalogos/subcategoria.dart'; 
import '../../models/catalogos/metodo_pago.dart';
import '../../models/catalogos/moneda.dart';
import '../../models/catalogos/tipo_transaccion.dart';
import '../../models/persona.dart'; 
import '../../models/finanzas/transaccion.dart'; // <-- ASEGÚRATE DE QUE ESTO ESTÉ IMPORTADO

class CrearTransaccionScreen extends StatefulWidget {
  final int? idMonedaPredeterminada; 
  final Transaccion? transaccionAEditar; // <-- NUEVO: Recibimos la transacción a editar

  const CrearTransaccionScreen({
    super.key, 
    this.idMonedaPredeterminada,
    this.transaccionAEditar, // <-- NUEVO
  });

  @override
  State<CrearTransaccionScreen> createState() => _CrearTransaccionScreenState();
}

class _CrearTransaccionScreenState extends State<CrearTransaccionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();
  
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController(); 
  
  int? _categoriaSeleccionada; 
  int? _subcategoriaSeleccionada;
  int? _metodoSeleccionado;
  int? _monedaSeleccionada;
  int? _tipoSeleccionado;   
  int? _personaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();

  bool _isSaving = false;   
  bool _isLoadingData = true; 

  List<Categoria> _categorias = []; 
  List<SubCategoria> _subcategorias = [];
  List<MetodoPago> _metodosPago = [];
  List<Moneda> _monedas = [];
  List<TipoTransaccion> _tiposTransaccion = [];
  List<Persona> _personas = []; 

  // Variable de ayuda para saber si estamos editando
  bool get _esEdicion => widget.transaccionAEditar != null; 

  @override
  void initState() {
    super.initState();
    
    // --- NUEVO: PRE-LLENAR CAMPOS DE TEXTO Y FECHA ---
    if (_esEdicion) {
      _montoController.text = widget.transaccionAEditar!.monto.toString();
      _conceptoController.text = widget.transaccionAEditar!.concepto ?? '';
      if (widget.transaccionAEditar!.fechaRegistro != null) {
        _fechaSeleccionada = widget.transaccionAEditar!.fechaRegistro!;
      }
    }
    
    _cargarListasDesplegables();
  }

  Future<void> _cargarListasDesplegables() async {
    try {
      final respuestas = await Future.wait([
        _catalogoService.getCategorias(), 
        _catalogoService.getSubCategorias(),
        _catalogoService.getMetodosPago(),
        _catalogoService.getMonedas(),
        _catalogoService.getTiposTransaccion(),
        _financeService.getPersonas(), 
      ]);
      
      if (!mounted) return;
      
      setState(() {
        _categorias = respuestas[0] as List<Categoria>;
        _subcategorias = respuestas[1] as List<SubCategoria>;
        _metodosPago = respuestas[2] as List<MetodoPago>;
        _monedas = respuestas[3] as List<Moneda>;
        _tiposTransaccion = respuestas[4] as List<TipoTransaccion>;
        _personas = respuestas[5] as List<Persona>; 

        // --- NUEVO: PRE-SELECCIONAR LOS CHIPS Y DROPDOWNS ---
        if (_esEdicion) {
          final tx = widget.transaccionAEditar!;
          
          _monedaSeleccionada = tx.monedaId;
          _tipoSeleccionado = tx.tipoTransaccionId;
          _metodoSeleccionado = tx.metodoPagoId;
          _personaSeleccionada = tx.personaId;
          _subcategoriaSeleccionada = tx.subcategoriaId;
          
          // Magia: Para que el dropdown de subcategorías funcione, necesitamos
          // encontrar a qué Categoría Padre pertenece la subcategoría seleccionada.
          if (_subcategoriaSeleccionada != null) {
            try {
              final subcat = _subcategorias.firstWhere((s) => s.idSubcategoria == _subcategoriaSeleccionada);
              _categoriaSeleccionada = subcat.categoriaId;
            } catch (_) {} // Ignorar si no se encuentra
          }
          
        } else {
          // Lógica original para crear (Nuevo)
          if (_monedas.isNotEmpty) {
            _monedaSeleccionada = widget.idMonedaPredeterminada ?? _monedas.first.idMoneda;
          }
          if (_tiposTransaccion.isNotEmpty) {
            _tipoSeleccionado = _tiposTransaccion.first.idTipoTransaccion;
          }
        }

        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar listas: $e')));
      }
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada, 
      firstDate: DateTime(2020),       
      lastDate: DateTime.now(),        
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF11998E)),
          ),
          child: child!,
        );
      },
    );

    if (seleccion != null) {
      final ahora = DateTime.now();
      final fechaConHoraActual = DateTime(
        seleccion.year, seleccion.month, seleccion.day,
        ahora.hour, ahora.minute, ahora.second,
      );
      setState(() {
        _fechaSeleccionada = fechaConHoraActual;
      });
    }
  }

  String get _simboloMonedaActual {
    if (_monedas.isEmpty || _monedaSeleccionada == null) return '';
    final moneda = _monedas.firstWhere((m) => m.idMoneda == _monedaSeleccionada, orElse: () => _monedas.first);
    return moneda.simbolo;
  }

  List<SubCategoria> get _subcategoriasFiltradas {
    if (_categoriaSeleccionada == null) return [];
    return _subcategorias.where((subcat) => subcat.categoriaId == _categoriaSeleccionada).toList();
  }

  void _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      if (_subcategoriaSeleccionada == null || _metodoSeleccionado == null || 
          _monedaSeleccionada == null || _tipoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan campos obligatorios'), backgroundColor: Colors.orange));
        return;
      }

      setState(() => _isSaving = true);
  
      Map<String, dynamic> datos = {
        'monto': _montoController.text,
        'subcategoria': _subcategoriaSeleccionada, 
        'tipo_transaccion': _tipoSeleccionado,
        'metodo_pago': _metodoSeleccionado,
        'moneda': _monedaSeleccionada,
        'fecha_registro': _fechaSeleccionada.toIso8601String(),
        if (_conceptoController.text.isNotEmpty) 'concepto': _conceptoController.text else 'concepto': null, 
        if (_personaSeleccionada != null) 'persona': _personaSeleccionada else 'persona': null, 
      };

      bool exito;
      
      // --- NUEVO: ¿CREAR O ACTUALIZAR? ---
      if (_esEdicion) {
        // Asegúrate de tener este método en tu FinanceService
        exito = await _financeService.actualizarTransaccion(widget.transaccionAEditar!.idTransaccion, datos);
      } else {
        exito = await _financeService.crearTransaccion(datos);
      }

      setState(() => _isSaving = false);

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF11998E), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            elevation: 10,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Mensaje dinámico
                        _esEdicion ? '¡Transacción Actualizada!' : '¡Transacción Guardada!', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context, true);
        
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _esEdicion ? 'Error al actualizar. Intenta de nuevo.' : 'Error al guardar. Intenta de nuevo.', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
                  ),
                ),
              ],
            ),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        // Título dinámico
        title: Text(_esEdicion ? 'Editar Operación' : 'Nueva Operación', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
      ),
      body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF11998E)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. EL MONTO
                      const Center(child: Text('Monto de Transacción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 10),
                            child: Text(_simboloMonedaActual, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey.shade300),
                        ),
                        validator: (value) => value!.isEmpty ? 'Ingresa el monto' : null,
                      ),
                      const SizedBox(height: 40),

                      // 2. MONEDA Y TIPO
                      const Text('Detalles Principales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      
                      const Text('Moneda', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      Wrap( 
                        spacing: 12.0, runSpacing: 12.0,
                        children: _monedas.map((moneda) {
                          final isSelected = _monedaSeleccionada == moneda.idMoneda;
                          return ChoiceChip(
                            label: Text(moneda.simbolo),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF2D3142), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            selected: isSelected,
                            onSelected: (bool selected) => setState(() => _monedaSeleccionada = moneda.idMoneda),
                            selectedColor: const Color(0xFF11998E),
                            backgroundColor: const Color(0xFFF5F7FA),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      const Text('Flujo', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12.0, runSpacing: 12.0,
                        children: _tiposTransaccion.map((tipo) {
                          final esEntrada = tipo.nombre.toLowerCase().contains('entrada') || tipo.nombre.toLowerCase().contains('ingreso');
                          final isSelected = _tipoSeleccionado == tipo.idTipoTransaccion;
                          return ChoiceChip(
                            label: Text(tipo.nombre),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF2D3142), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            selected: isSelected,
                            onSelected: (bool selected) => setState(() => _tipoSeleccionado = tipo.idTipoTransaccion),
                            selectedColor: esEntrada ? const Color(0xFF38EF7D) : const Color(0xFFFF5252),
                            backgroundColor: const Color(0xFFF5F7FA),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),

                      // 3. CLASIFICACIÓN
                      const Text('Clasificación', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Categoría Principal',
                          filled: true, fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF11998E)),
                        ),
                        value: _categoriaSeleccionada,
                        items: _categorias.map((categoria) => DropdownMenuItem<int>(value: categoria.idCategoria, child: Text(categoria.nombre, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _categoriaSeleccionada = newValue;
                            _subcategoriaSeleccionada = null; 
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Subcategoría',
                          filled: true, fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.subdirectory_arrow_right, color: Color(0xFF11998E)),
                        ),
                        value: _subcategoriaSeleccionada,
                        onChanged: _categoriaSeleccionada == null 
                            ? null 
                            : (int? newValue) => setState(() => _subcategoriaSeleccionada = newValue),
                        hint: Text(_categoriaSeleccionada == null ? 'Primero elige una Categoría' : 'Selecciona'),
                        items: _subcategoriasFiltradas.map((subcategoria) => DropdownMenuItem<int>(value: subcategoria.idSubcategoria, child: Text(subcategoria.nombre, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Color(0xFF11998E)),
                        title: const Text('Fecha de transacción'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)), 
                        trailing: const Icon(Icons.edit, size: 20),
                        onTap: () => _seleccionarFecha(context),
                      ),
                      
                      // 4. OTROS DETALLES
                      const Text('Otros Detalles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Método de Pago',
                          filled: true, fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF11998E)),
                        ),
                        value: _metodoSeleccionado,
                        items: _metodosPago.map((metodo) => DropdownMenuItem<int>(value: metodo.idMetodoPago, child: Text(metodo.nombre, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                        onChanged: (int? newValue) => setState(() => _metodoSeleccionado = newValue),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Persona (Opcional)',
                          filled: true, fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF11998E)),
                        ),
                        value: _personaSeleccionada,
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('Ninguna', style: TextStyle(color: Colors.grey))),
                          ..._personas.map((persona) => DropdownMenuItem<int>(value: persona.idPersona, child: Text(persona.nombre, style: const TextStyle(fontWeight: FontWeight.w500)))),
                        ],
                        onChanged: (int? newValue) => setState(() => _personaSeleccionada = newValue),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _conceptoController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Concepto / Descripción (Opcional)',
                          alignLabelWithHint: true,
                          filled: true, fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 20), child: Icon(Icons.description_outlined, color: Color(0xFF11998E))),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // BOTÓN GUARDAR / ACTUALIZAR
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF11998E).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, 
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSaving ? null : _guardarTransaccion,
                          child: _isSaving
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              // Texto del botón dinámico
                              : Text(_esEdicion ? 'Actualizar Transacción' : 'Guardar Transacción', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}