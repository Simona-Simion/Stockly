import 'scanner/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/receta_provider.dart';
import '../repositories/operacion_sync_repository.dart';
import 'productos/productos_screen.dart';
import 'recetas/recetas_screen.dart';
import 'ventas/registrar_venta_screen.dart';
import 'mermas/registrar_merma_screen.dart';
import 'movimientos/movimientos_screen.dart';

//import 'package:supabase_flutter/supabase_flutter.dart';

// Pantalla principal con navegación inferior entre las secciones de la app.
// Las secciones visibles dependen del rol del usuario (ADMIN / EMPLEADO).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;
  final _movimientosKey = GlobalKey<MovimientosScreenState>();
  final OperacionSyncRepository _operacionSyncRepository =
      OperacionSyncRepository();
  bool _reintentandoSincronizacion = false;

  void _onTabChanged(int indice) {
    setState(() => _indiceActual = indice);

    final esAdmin = context.read<AuthProvider>().esAdmin;

    if (esAdmin) {
      switch (indice) {
        case 0:
          context.read<ProductoProvider>().cargar();
          break;
        case 1:
          context.read<RecetaProvider>().cargar();
          break;
        default:
          break;
      }
    }
  }

  Future<void> _reintentarSincronizacion() async {
    if (_reintentandoSincronizacion) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    setState(() => _reintentandoSincronizacion = true);

    try {
      await _operacionSyncRepository.reintentarErroresYConflictos();

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Reintento de sincronizacion ejecutado.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al reintentar la sincronizacion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reintentandoSincronizacion = false);
      }
    }
  }

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
      MovimientosScreen(key: _movimientosKey),
      const ScannerScreen(),
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
      const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: 'Escanear',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reintentandoSincronizacion
                    ? null
                    : _reintentarSincronizacion,
                icon: _reintentandoSincronizacion
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _reintentandoSincronizacion
                      ? 'Reintentando sincronizacion...'
                      : 'Reintentar sincronizacion',
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              // IndexedStack mantiene el estado de todas las pantallas
              index: indiceSeguro,
              children: pantallas,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceSeguro,
        onDestinationSelected: _onTabChanged,
        destinations: destinos,
      ),
    );
  }
}
