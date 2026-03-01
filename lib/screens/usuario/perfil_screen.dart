import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'editar_perfil_screen.dart'; 

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  void _cargarPerfil() async {
    final data = await _authService.getPerfil();
    setState(() {
      _perfilData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris ultra claro
      appBar: AppBar(
        title: const Text('Mi Cuenta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : _perfilData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      const Text('Error al cargar el perfil', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 100),
                  child: Column(
                    children: [
                      // --- FOTO DE PERFIL GIGANTE ---
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4), // Borde blanco alrededor
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: const Color(0xFF4A00E0).withOpacity(0.1), // Morado suave
                            child: Text(
                              _perfilData!['username'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF4A00E0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '@${_perfilData!['username']}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 40),
                      
                      // --- TARJETA DE DATOS (Estilo Panel de Control) ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Nombre Completo',
                              value: '${_perfilData!['first_name'] ?? ''} ${_perfilData!['last_name'] ?? ''}'.trim().isEmpty
                                    ? 'No definido'
                                    : '${_perfilData!['first_name']} ${_perfilData!['last_name']}',
                            ),
                            const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                            
                            _buildInfoRow(
                              icon: Icons.email_outlined,
                              label: 'Correo Electrónico',
                              value: _perfilData!['email'] != null && _perfilData!['email'].toString().isNotEmpty
                                    ? _perfilData!['email']
                                    : 'Sin correo registrado',
                            ),
                            const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                            
                            _buildInfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Fecha Nacimiento',
                              value: _perfilData!['fecha_nacimiento'] != null && _perfilData!['fecha_nacimiento'].toString().isNotEmpty
                                    ? _perfilData!['fecha_nacimiento']
                                    : 'No registrada',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

        floatingActionButton: _perfilData != null 
        ? Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditarPerfilScreen(perfilActual: _perfilData!)),
                );

                if (resultado == true) {
                  setState(() => _isLoading = true);
                  _cargarPerfil();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil actualizado!'), backgroundColor: Color(0xFF38EF7D)));
                  }
                }
              },
            ),
          )
        : null,
    );
  }

  // Widget reutilizable para cada renglón de información
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF4A00E0), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Color(0xFF2D3142), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}