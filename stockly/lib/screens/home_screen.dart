import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'productos/productos_screen.dart';
import 'recetas/recetas_screen.dart';
import 'ventas/registrar_venta_screen.dart';
import 'mermas/registrar_merma_screen.dart';
import 'movimientos/movimientos_screen.dart';

// Pantalla principal con navegación inferior entre las secciones de la app.
// Las secciones visibles dependen del rol del usuario (ADMIN / EMPLEADO).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final esAdmin = auth.esAdmin;
    final nombreUsuario = auth.usuario?.nombre ?? auth.usuario?.email ?? '';

    // ADMIN ve todas las secciones; EMPLEADO solo las operativas
    final pantallas = [
      if (esAdmin) const ProductosScreen(),
      if (esAdmin) const RecetasScreen(),
      const RegistrarVentaScreen(),
      const RegistrarMermaScreen(),
      const MovimientosScreen(),
    ];

    final destinos = [
      if (esAdmin)
        const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Productos',
        ),
      if (esAdmin)
        const NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Recetas',
        ),
      const NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: 'Venta',
      ),
      const NavigationDestination(
        icon: Icon(Icons.delete_outline),
        selectedIcon: Icon(Icons.delete),
        label: 'Merma',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Historial',
      ),
    ];

    // Ajusta el índice si cambia el número de pestañas (p.ej. al cargar el perfil)
    final indiceSeguro = _indiceActual.clamp(0, pantallas.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stockly'),
        actions: [
          if (nombreUsuario.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  nombreUsuario,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        // IndexedStack mantiene el estado de todas las pantallas
        index: indiceSeguro,
        children: pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceSeguro,
        onDestinationSelected: (indice) {
          setState(() => _indiceActual = indice);
        },
        destinations: destinos,
      ),
    );
  }
}
