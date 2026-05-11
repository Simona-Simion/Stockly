import 'scanner/scanner_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../providers/alerta_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/receta_provider.dart';
import '../repositories/operacion_sync_repository.dart';
import '../services/local_database_service.dart';
import 'inicio/inicio_screen.dart';
import 'productos/producto_form_screen.dart';
import 'productos/productos_screen.dart';
import 'pedidos/pedidos_proveedor_screen.dart';
import 'recetas/receta_form_screen.dart';
import 'recetas/recetas_screen.dart';
import 'stock/entrada_stock_screen.dart';
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
  int _inicioRefreshToken = 0;
  final _movimientosKey = GlobalKey<MovimientosScreenState>();
  final OperacionSyncRepository _operacionSyncRepository =
      OperacionSyncRepository();
  bool _reintentandoSincronizacion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertaProvider>().cargar();
    });
  }

  void _onTabChanged(int indice) {
    setState(() {
      _indiceActual = indice;
      if (indice == 0) {
        _inicioRefreshToken++;
      }
    });

    final esAdmin = context.read<AuthProvider>().esAdmin;

    if (esAdmin) {
      switch (indice) {
        case 1:
          context.read<ProductoProvider>().cargar();
          break;
        case 2:
          context.read<RecetaProvider>().cargar();
          break;
        default:
          break;
      }
    }
  }

  Future<void> _abrirEntradaStock() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EntradaStockScreen()),
    );

    if (mounted) {
      context.read<ProductoProvider>().cargar();
      context.read<AlertaProvider>().cargar();
    }
  }

  Future<void> _abrirNuevoProducto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductoFormScreen()),
    );

    if (mounted) {
      context.read<ProductoProvider>().cargar();
      context.read<AlertaProvider>().cargar();
    }
  }

  Future<void> _abrirNuevaReceta() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecetaFormScreen()),
    );

    if (mounted) {
      context.read<RecetaProvider>().cargar();
    }
  }

  Future<void> _abrirScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (mounted) {
      context.read<ProductoProvider>().cargar();
      context.read<AlertaProvider>().cargar();
    }
  }

  Future<void> _abrirPedidosProveedor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PedidosProveedorScreen()),
    );
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

      await context.read<AlertaProvider>().cargar();

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Reintento de sincronización ejecutado.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al reintentar la sincronización: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reintentandoSincronizacion = false);
      }
    }
  }

  Future<void> _mostrarAlertasStock() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AlertasStockSheet(),
    );
  }

  Future<void> _mostrarAcciones() async {
    final esAdmin = context.read<AuthProvider>().esAdmin;
    final localDatabaseSoportada = LocalDatabaseService.instance.isSupported;
    final mostrarScanner = localDatabaseSoportada && !kIsWeb;
    final mostrarReintentarSync = localDatabaseSoportada;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (esAdmin)
                    _AccionItem(
                      icon: Icons.add,
                      titulo: 'Nuevo producto',
                      onTap: () =>
                          _cerrarYEjecutar(sheetContext, _abrirNuevoProducto),
                    ),
                  if (esAdmin)
                    _AccionItem(
                      icon: Icons.menu_book_outlined,
                      titulo: 'Nueva receta',
                      onTap: () =>
                          _cerrarYEjecutar(sheetContext, _abrirNuevaReceta),
                    ),
                  if (esAdmin)
                    _AccionItem(
                      icon: Icons.add_shopping_cart,
                      titulo: 'Entrada de stock',
                      onTap: () =>
                          _cerrarYEjecutar(sheetContext, _abrirEntradaStock),
                    ),
                  if (mostrarScanner)
                    _AccionItem(
                      icon: Icons.qr_code_scanner,
                      titulo: 'Escanear producto',
                      onTap: () =>
                          _cerrarYEjecutar(sheetContext, _abrirScanner),
                    ),
                  _AccionItem(
                    icon: Icons.receipt_long_outlined,
                    titulo: 'Pedidos proveedor',
                    onTap: () =>
                        _cerrarYEjecutar(sheetContext, _abrirPedidosProveedor),
                  ),
                  if (mostrarReintentarSync)
                    _AccionItem(
                      icon: Icons.sync,
                      titulo: _reintentandoSincronizacion
                          ? 'Reintentando sincronizacion...'
                          : 'Reintentar sincronizacion',
                      enabled: !_reintentandoSincronizacion,
                      onTap: () => _cerrarYEjecutar(
                        sheetContext,
                        _reintentarSincronizacion,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _cerrarYEjecutar(
    BuildContext sheetContext,
    Future<void> Function() accion,
  ) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        accion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final alertaProvider = context.watch<AlertaProvider>();
    final esAdmin = auth.esAdmin;
    final nombreUsuario = auth.usuario?.nombre ?? auth.usuario?.email ?? '';

    final pantallas = [
      InicioScreen(
        nombreUsuario: nombreUsuario,
        refreshToken: _inicioRefreshToken,
      ),
      if (esAdmin) const ProductosScreen(),
      if (esAdmin) const RecetasScreen(),
      const RegistrarVentaScreen(),
      const RegistrarMermaScreen(),
      MovimientosScreen(key: _movimientosKey),
    ];

    final destinos = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
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

    final indiceSeguro = _indiceActual.clamp(0, pantallas.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stockly'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Alertas de stock',
              onPressed: _mostrarAlertasStock,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    alertaProvider.tieneAlertas
                        ? Icons.warning_amber_rounded
                        : Icons.notifications_none_rounded,
                  ),
                  if (alertaProvider.alertas.isNotEmpty)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          alertaProvider.alertas.length.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _mostrarAcciones,
                icon: const Icon(Icons.apps),
                label: const Text('Acciones'),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: indiceSeguro, children: pantallas),
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

class _AccionItem extends StatelessWidget {
  const _AccionItem({
    required this.icon,
    required this.titulo,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String titulo;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(titulo),
      onTap: enabled ? onTap : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _AlertasStockSheet extends StatelessWidget {
  const _AlertasStockSheet();

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) {
      return cantidad.toInt().toString();
    }
    return cantidad.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
        child: Consumer<AlertaProvider>(
          builder: (context, provider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Alertas de stock', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: provider.cargando
                          ? null
                          : () => context.read<AlertaProvider>().cargar(),
                      tooltip: 'Recargar alertas',
                      icon: provider.cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // FIX:
                // Mejor usar una altura máxima controlada en el modal que Flexible,
                // para evitar comportamientos raros en web/móvil.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Builder(
                    builder: (_) {
                      if (provider.cargando && !provider.cargadoInicial) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No se pudieron cargar las alertas de stock.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        );
                      }

                      if (!provider.tieneAlertas) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No hay alertas de stock.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: provider.alertas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final producto = provider.alertas[index];
                          return _AlertaStockItem(
                            producto: producto,
                            formatearCantidad: _formatearCantidad,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertaStockItem extends StatelessWidget {
  const _AlertaStockItem({
    required this.producto,
    required this.formatearCantidad,
  });

  final Producto producto;
  final String Function(double) formatearCantidad;

  bool get _esCritico => producto.stockActual <= 0;

  @override
  Widget build(BuildContext context) {
    final color = _esCritico ? Colors.red : Colors.orange;
    final estado = _esCritico ? 'Critico' : 'Stock bajo';
    final unidad = producto.unidadMedidaNombre != null
        ? ' ${producto.unidadMedidaNombre}'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  producto.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  estado,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stock actual: ${formatearCantidad(producto.stockActual)}$unidad',
          ),
          Text(
            'Stock minimo: ${formatearCantidad(producto.stockMinimo)}$unidad',
          ),
          const SizedBox(height: 4),
          Text(
            'Reposicion necesaria',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
