import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../models/receta.dart';
import '../../providers/producto_provider.dart';
import '../../providers/receta_provider.dart';
import '../../repositories/venta_repository.dart';
import '../../services/venta_service.dart';

// Pantalla para registrar una venta.
// Pestaña "Por receta": aplica el escandallo automático.
// Pestaña "Por producto": venta directa sin receta.
class RegistrarVentaScreen extends StatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  State<RegistrarVentaScreen> createState() => _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends State<RegistrarVentaScreen>
    with SingleTickerProviderStateMixin {
  final VentaService _ventaService =
      VentaService(repository: VentaRepository());

  late final TabController _tabController;

  // ── Estado pestaña "Por receta" ──────────────────────────────────────────
  Receta? _recetaSeleccionada;
  int _cantidad = 1;
  bool _registrando = false;

  // ── Estado pestaña "Por producto" ────────────────────────────────────────
  Producto? _productoSeleccionado;
  int _cantidadProducto = 1;
  bool _registrandoProducto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetaProvider>().cargar();
      context.read<ProductoProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) {
      return cantidad.toInt().toString();
    }
    return cantidad.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar venta'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Por receta'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Por producto'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabReceta(),
          _buildTabProducto(),
        ],
      ),
    );
  }

  // ── PESTAÑA "POR RECETA" (contenido original sin cambios) ────────────────

  Widget _buildTabReceta() {
    final recetas = context.watch<RecetaProvider>().recetas;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de receta
          const Text('Receta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Receta>(
            value: _recetaSeleccionada,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecciona una receta',
            ),
            items: recetas
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.nombre),
                    ))
                .toList(),
            onChanged: (r) => setState(() => _recetaSeleccionada = r),
          ),
          const SizedBox(height: 24),

          // Vista previa de los ingredientes de la receta seleccionada
          if (_recetaSeleccionada != null) ...[
            const Text('Ingredientes que se descontarán:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _recetaSeleccionada!.lineas
                    .map((l) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.remove_circle_outline,
                              color: Colors.orange, size: 18),
                          title: Text(l.productoNombre),
                          trailing: Text(
                            '${_formatearCantidad(l.cantidad * _cantidad)} ${l.unidadMedida ?? ''}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Precio total estimado
            if (_recetaSeleccionada!.precioVenta != null)
              Text(
                'Total: ${(_recetaSeleccionada!.precioVenta! * _cantidad).toStringAsFixed(2)} €',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
          ],

          // Selector de cantidad con botones + y -
          const Text('Cantidad',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                onPressed:
                    _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Text(
                '$_cantidad',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                onPressed: () => setState(() => _cantidad++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Spacer(),

          // Botón de confirmar venta
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_recetaSeleccionada == null || _registrando)
                  ? null
                  : _registrarVenta,
              icon: _registrando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.point_of_sale),
              label: const Text('Confirmar venta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PESTAÑA "POR PRODUCTO" ───────────────────────────────────────────────

  Widget _buildTabProducto() {
    final productos = context.watch<ProductoProvider>().productos
        .where((p) => p.activo)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de producto
          const Text('Producto',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Producto>(
            value: _productoSeleccionado != null
                ? productos.where((p) => p.id == _productoSeleccionado!.id).firstOrNull
                : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecciona un producto',
            ),
            items: productos
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.nombre),
                    ))
                .toList(),
            onChanged: (p) => setState(() => _productoSeleccionado = p),
          ),
          const SizedBox(height: 24),

          // Info del producto seleccionado
          if (_productoSeleccionado != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined,
                    color: Colors.blue),
                title: Text(_productoSeleccionado!.nombre),
                subtitle: Text(
                  'Stock disponible: ${_formatearCantidad(_productoSeleccionado!.stockActual)}'
                  '${_productoSeleccionado!.unidadMedidaNombre != null ? ' ${_productoSeleccionado!.unidadMedidaNombre}' : ''}',
                ),
                trailing: _productoSeleccionado!.precioUnidad != null
                    ? Text(
                        '${(_productoSeleccionado!.precioUnidad! * _cantidadProducto).toStringAsFixed(2)} €',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Selector de cantidad
          const Text('Cantidad',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                onPressed: _cantidadProducto > 1
                    ? () => setState(() => _cantidadProducto--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Text(
                '$_cantidadProducto',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                onPressed: () => setState(() => _cantidadProducto++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Spacer(),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_productoSeleccionado == null || _registrandoProducto)
                      ? null
                      : _registrarVentaProducto,
              icon: _registrandoProducto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.point_of_sale),
              label: const Text('Confirmar venta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACCIONES ─────────────────────────────────────────────────────────────

  Future<void> _registrarVenta() async {
    if (_recetaSeleccionada == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final receta = _recetaSeleccionada!;
        return AlertDialog(
          title: Text('¿Confirmar ${_cantidad}x ${receta.nombre}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Se descontará:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...receta.lineas.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${l.productoNombre}  '
                      '${_formatearCantidad(l.cantidad * _cantidad)} '
                      '${l.unidadMedida ?? ''}',
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) return;

    setState(() => _registrando = true);
    try {
      await _ventaService.registrar(_recetaSeleccionada!.id, _cantidad);
      if (mounted) {
        setState(() {
          _recetaSeleccionada = null;
          _cantidad = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta registrada. Stock descontado.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  Future<void> _registrarVentaProducto() async {
    if (_productoSeleccionado == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final producto = _productoSeleccionado!;
        return AlertDialog(
          title: Text('¿Confirmar ${_cantidadProducto}x ${producto.nombre}?'),
          content: Text(
            'Se descontarán $_cantidadProducto unidades de ${producto.nombre} del stock.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) return;

    setState(() => _registrandoProducto = true);
    try {
      await _ventaService.registrarProducto(
          _productoSeleccionado!.id, _cantidadProducto);
      if (mounted) {
        setState(() {
          _productoSeleccionado = null;
          _cantidadProducto = 1;
        });
        // Recargar productos para reflejar el stock actualizado
        context.read<ProductoProvider>().cargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta registrada. Stock descontado.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _registrandoProducto = false);
    }
  }
}
