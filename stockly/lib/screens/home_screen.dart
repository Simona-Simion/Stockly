import 'package:flutter/material.dart';

import 'productos/productos_screen.dart';
import 'recetas/recetas_screen.dart';
import 'ventas/registrar_venta_screen.dart';
import 'mermas/registrar_merma_screen.dart';
import 'movimientos/movimientos_screen.dart';

// Pantalla principal con navegación inferior entre las 5 secciones de la app.
// El índice seleccionado controla qué pantalla se muestra en el cuerpo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;

  // Las 5 secciones de la app en el orden del BottomNavigationBar
  final List<Widget> _pantallas = const [
    ProductosScreen(),
    RecetasScreen(),
    RegistrarVentaScreen(),
    RegistrarMermaScreen(),
    MovimientosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // IndexedStack mantiene el estado de todas las pantallas aunque
        // el usuario cambie de pestaña (no recarga al volver)
        index: _indiceActual,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (indice) {
          setState(() => _indiceActual = indice);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recetas',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Venta',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete),
            label: 'Merma',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
