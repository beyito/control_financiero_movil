import 'package:flutter/material.dart';
import '../services/finance_service.dart';
import '../services/catalogo_service.dart';

// Importa aquí tus modelos, asegúrate de que la ruta sea correcta
// import '../models/catalogos/categoria.dart'; 
import '../models/catalogos/subcategoria.dart'; 
import '../models/catalogos/metodo_pago.dart';
import '../models/catalogos/moneda.dart';
import '../models/catalogos/tipo_transaccion.dart';
import '../models/catalogos/tipo_movimiento.dart';

 // Ajusta la ruta a donde tengas tus modelos

class CrearTransaccionScreen extends StatefulWidget {
  const CrearTransaccionScreen({super.key});

  @override
  State<CrearTransaccionScreen> createState() => _CrearTransaccionScreenState();
}

class _CrearTransaccionScreenState extends State<CrearTransaccionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FinanceService _financeService = FinanceService();
  final CatalogoService _catalogoService = CatalogoService();
  final TextEditingController _montoController = TextEditingController();

  int? _subcategoriaSeleccionada;
  int? _metodoSeleccionado;
  int? _monedaSeleccionada;
  int? _tipoSeleccionado;   

  bool _isSaving = false;   
  bool _isLoadingData = true; 

  // Listas vacías para todas las opciones del backend
  List<SubCategoria> _subcategorias = [];
  List<MetodoPago> _metodosPago = [];
  List<Moneda> _monedas = [];
  List<TipoTransaccion> _tiposTransaccion = [];

  @override
  void initState() {
    super.initState();
    _cargarListasDesplegables();
  }

  // Descargamos TODAS las listas en paralelo
  Future<void> _cargarListasDesplegables() async {
    try {
      final respuestas = await Future.wait([
        _catalogoService.getSubCategorias(),
        _catalogoService.getMetodosPago(),
        _catalogoService.getMonedas(),
        _catalogoService.getTiposTransaccion(),
      ]);

      setState(() {
        _subcategorias = respuestas[0] as List<SubCategoria>;
        _metodosPago = respuestas[1] as List<MetodoPago>;
        _monedas = respuestas[2] as List<Moneda>;
        _tiposTransaccion = respuestas[3] as List<TipoTransaccion>;

        // Seleccionar el primer elemento por defecto para las opciones de botones
        if (_monedas.isNotEmpty) _monedaSeleccionada = _monedas.first.idMoneda;
        if (_tiposTransaccion.isNotEmpty) _tipoSeleccionado = _tiposTransaccion.first.idTipoTransaccion;

        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar listas: $e')),
        );
      }
    }
  }

  // Obtenemos el símbolo de la moneda actualmente seleccionada
  String get _simboloMonedaActual {
    if (_monedas.isEmpty || _monedaSeleccionada == null) return '';
    final moneda = _monedas.firstWhere(
      (m) => m.idMoneda == _monedaSeleccionada, 
      orElse: () => _monedas.first
    );
    return moneda.simbolo;
  }

  void _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      if (_subcategoriaSeleccionada == null || _metodoSeleccionado == null || 
          _monedaSeleccionada == null || _tipoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, completa todos los campos')),
        );
        return;
      }

      setState(() => _isSaving = true);

      Map<String, dynamic> datos = {
        'monto': _montoController.text,
        'subcategoria': _subcategoriaSeleccionada,
        'tipo_transaccion': _tipoSeleccionado,
        'metodo_pago': _metodoSeleccionado,
        'moneda': _monedaSeleccionada,
      };

      bool exito = await _financeService.crearTransaccion(datos);

      setState(() => _isSaving = false);

      if (exito && mounted) {
        Navigator.pop(context, true); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar. Revisa la consola.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Transacción'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 1. EL MONTO (Con símbolo totalmente dinámico desde la BD)
                    TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 14.0, left: 16.0, right: 12.0),
                          child: Text(
                            _simboloMonedaActual, // <--- Símbolo dinámico automático
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.green.shade700
                            ),
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingresa el monto' : null,
                    ),
                    const SizedBox(height: 24),

                    // 2. MONEDA (Generada dinámicamente)
                    const Text('Moneda', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap( // Usamos Wrap por si tienes muchas monedas, para que pasen a la línea de abajo
                      spacing: 12.0,
                      children: _monedas.map((moneda) {
                        return ChoiceChip(
                          label: Text('${moneda.simbolo} (${moneda.nombre})'),
                          selected: _monedaSeleccionada == moneda.idMoneda,
                          onSelected: (bool selected) {
                            setState(() => _monedaSeleccionada = moneda.idMoneda);
                          },
                          selectedColor: Colors.green.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 3. TIPO DE TRANSACCIÓN (Generada dinámicamente)
                    const Text('Tipo de Transacción', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12.0,
                      children: _tiposTransaccion.map((tipo) {
                        // Verificamos si es ingreso para pintarlo verde, si no rojo
                        final esEntrada = tipo.nombre.toLowerCase().contains('entrada') || 
                                          tipo.nombre.toLowerCase().contains('ingreso');
                        return ChoiceChip(
                          label: Text(tipo.nombre),
                          selected: _tipoSeleccionado == tipo.idTipoTransaccion,
                          onSelected: (bool selected) {
                            setState(() => _tipoSeleccionado = tipo.idTipoTransaccion);
                          },
                          selectedColor: esEntrada ? Colors.green.shade200 : Colors.red.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 4. CATEGORÍA (Menú desplegable dinámico)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _subcategoriaSeleccionada,
                      items: _subcategorias.map((subcategoria) {
                        return DropdownMenuItem<int>(
                          value: subcategoria.idSubcategoria,
                          child: Text(subcategoria.nombre),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _subcategoriaSeleccionada = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. MÉTODO DE PAGO (Menú desplegable dinámico)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      value: _metodoSeleccionado,
                      items: _metodosPago.map((metodo) {
                        return DropdownMenuItem<int>(
                          value: metodo.idMetodoPago,
                          child: Text(metodo.nombre),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _metodoSeleccionado = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // BOTÓN GUARDAR
                    _isSaving 
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _guardarTransaccion,
                            child: const Text('Guardar Transacción', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}