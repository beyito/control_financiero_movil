import 'package:control_financiero/screens/reporte_screen.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'persona/persona_screen.dart';
import 'cuenta_corriente/cuenta_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Aquí controlamos qué pestaña está seleccionada (0 = Inicio, 1 = Personas, etc.)
  int _selectedIndex = 0;

  // Esta es la lista de pantallas que se mostrarán según la pestaña seleccionada
  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const CuentasScreen(),
    const PersonasScreen(),
    const ReportesScreen(), // Pantalla de relleno para el 3er botón
  ];
  
  // Método que se llama al tocar un botón de la barra inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El body cambia dinámicamente según el índice seleccionado
      body: _pantallas[_selectedIndex],
      
      // La barra de navegación inferior
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance), // Ícono de cuentas
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Personas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green, // Color cuando está seleccionado
        unselectedItemColor: Colors.grey, // Color cuando no lo está
        onTap: _onItemTapped,
      ),
    );
  }
}