import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ia_service.dart'; 

class DictadoScreen extends StatefulWidget {
  const DictadoScreen({super.key});

  @override
  _DictadoScreenState createState() => _DictadoScreenState();
}

class _DictadoScreenState extends State<DictadoScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _estaProcesando = false;

  // 1. EL CONTROLADOR: Nos permite leer y escribir en la caja de texto
  final TextEditingController _textController = TextEditingController();
  
  // Variable para guardar lo que estaba escrito antes de volver a presionar el micrófono
  String _textoBase = ''; 

  final IAService _iaService = IAService(); // Asegúrate de que tu clase se llame IaService o IAService según tu archivo

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose(); // Siempre limpiar el controlador para liberar memoria
    super.dispose();
  }

  // 2. LÓGICA HÍBRIDA DE VOZ Y TEXTO
  void _toggleEscuchar() async {
    // Escondemos el teclado si estaba abierto al presionar el micrófono
    FocusScope.of(context).unfocus(); 

    if (!_isListening) {
      bool disponible = await _speech.initialize(
        onStatus: (status) {
          // Si el celular deja de escuchar automáticamente por silencio, actualizamos el botón
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );

      if (disponible) {
        // Guardamos lo que ya estaba escrito en la caja de texto
        _textoBase = _textController.text;
        
        // Si ya había texto, le agregamos un espacio al final para que no se peguen las palabras
        if (_textoBase.isNotEmpty && !_textoBase.endsWith(' ')) {
          _textoBase += ' ';
        }

        setState(() => _isListening = true);
        
        _speech.listen(
          onResult: (resultado) {
            setState(() {
              // Concatenamos lo antiguo con lo nuevo que se va escuchando
              _textController.text = _textoBase + resultado.recognizedWords;
              
              // Movemos el cursor al final del texto para que el usuario pueda seguir escribiendo
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length)
              );
            });
          },
          localeId: 'es_ES', 
        );
      }
    } else {
      // Si ya estaba escuchando y el usuario lo presiona para detenerlo
      setState(() => _isListening = false);
      _speech.stop();
      // Ya NO llamamos a _enviarAlBackend aquí.
    }
  }

  // 3. ENVÍO MANUAL Y CONTROL DE ESTADO
  Future<void> _enviarAlBackend() async {
    final textoFinal = _textController.text.trim();
    
    if (textoFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa o dicta un texto primero.')),
      );
      return;
    }

    setState(() => _estaProcesando = true);
    FocusScope.of(context).unfocus(); // Ocultar teclado durante la carga

    final resultado = await _iaService.procesarDictadoVoz(textoFinal);

    setState(() => _estaProcesando = false);

    // 4. VENTANAS AMIGABLES (Dialogs en lugar de mostrar errores técnicos)
    if (resultado['exito'] == true) {
      _mostrarDialogoAmigable(
        titulo: '¡Transacciones Registradas!',
        mensaje: 'Tu asistente guardó todo correctamente en tu base de datos.',
        esExito: true,
        icono: Icons.check_circle,
        color: const Color(0xFF11998E),
      );
    } else {
      // Aunque el backend devuelva un error técnico 500, mostramos algo bonito
      _mostrarDialogoAmigable(
        titulo: 'Ocurrió un contratiempo',
        mensaje: 'No pudimos procesar tu texto en este momento. Intenta redactarlo de forma más sencilla o revisa tu conexión.',
        esExito: false,
        icono: Icons.error_outline,
        color: Colors.redAccent,
      );
    }
  }

  void _mostrarDialogoAmigable({
    required String titulo, 
    required String mensaje, 
    required bool esExito,
    required IconData icono,
    required Color color
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // El usuario debe presionar el botón para cerrar
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(icono, size: 60, color: color),
            const SizedBox(height: 16),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
            ),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              if (esExito) {
                // Si fue un éxito, también cierra la pantalla de dictado 
                // y le avisa al Dashboard que recargue
                Navigator.pop(context, true); 
              }
            },
            child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo claro a juego con tu Dashboard
      appBar: AppBar(
        title: const Text('Asistente IA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- CAJA DE TEXTO PRINCIPAL ---
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null, // Permite que el texto crezca hacia abajo infinitamente
                    expands: true, // Hace que llene el contenedor
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 20, color: Color(0xFF2D3142), height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Ej: Gasté 30 bs en pollo y pagué con QR...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(24),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // --- ZONA DE CONTROLES (Cargando o Botones) ---
              if (_estaProcesando)
                Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF11998E)),
                    const SizedBox(height: 16),
                    Text('La IA está analizando tus gastos...', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón de Micrófono
                    GestureDetector(
                      onTap: _toggleEscuchar,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.redAccent : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.redAccent : Colors.grey).withOpacity(0.3), 
                              blurRadius: 15, 
                              offset: const Offset(0, 5)
                            )
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none, 
                          color: _isListening ? Colors.white : const Color(0xFF2D3142), 
                          size: 36
                        ),
                      ),
                    ),

                    // Botón de Enviar
                    ElevatedButton.icon(
                      onPressed: _enviarAlBackend,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text('Procesar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11998E),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                        shadowColor: const Color(0xFF11998E).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}