import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../scanner/scanner_screen.dart';
import 'producto_detalle_screen.dart';
import 'producto_form_screen.dart';

// Pantalla principal de productos: listado con búsqueda y acceso al formulario.
// Los productos con stock por debajo del mínimo se marcan en rojo.
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final TextEditingController _busqueda = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    // Carga los productos al abrir la pantalla por primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear código de barras',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => context.read<ProductoProvider>().cargar(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busqueda,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busqueda.clear();
                          setState(() => _filtro = '');
                        },
                      )
                    : null,
              ),
              onChanged: (valor) => setState(() => _filtro = valor.toLowerCase()),
            ),
          ),

          // Lista de productos
          Expanded(child: _buildLista()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
    );
  }

  Widget _buildLista() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, _) {
        if (provider.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildError(provider.error!);
        }

        // Filtra la lista según lo que escribe el usuario en el buscador
        final lista = provider.productos
            .where((p) => p.nombre.toLowerCase().contains(_filtro))
            .toList();

        if (lista.isEmpty) {
          return const Center(
            child: Text('No hay productos', style: TextStyle(color: Colors.grey)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<ProductoProvider>().cargar(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: lista.length,
            itemBuilder: (context, i) => _ProductoCard(
              producto: lista[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductoDetalleScreen(producto: lista[i]),
                ),
              ),
              onEditar: () => _abrirFormulario(context, producto: lista[i]),
              onEliminar: () => _confirmarEliminar(context, lista[i]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<ProductoProvider>().cargar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {Producto? producto}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(producto: producto),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar producto'),
        content: Text('¿Desactivar "${producto.nombre}"? No aparecerá en el inventario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ProductoProvider>().desactivar(producto.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${producto.nombre}" desactivado')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }
}

// Tarjeta individual de cada producto en el listado
class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ProductoCard({
    required this.producto,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final bajoMinimo = producto.bajominimo;
    final colorBorde = bajoMinimo ? Colors.red.shade300 : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorBorde, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: bajoMinimo
              ? Colors.red.shade100
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.inventory_2,
            color: bajoMinimo
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock actual con indicador visual si está bajo mínimo
            Row(
              children: [
                Text(
                  'Stock: ${producto.stockActual.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: bajoMinimo ? Colors.red : null,
                    fontWeight: bajoMinimo ? FontWeight.bold : null,
                  ),
                ),
                if (producto.unidadMedidaNombre != null)
                  Text(' ${producto.unidadMedidaNombre}'),
                if (bajoMinimo) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber, size: 14, color: Colors.red),
                  const Text(
                    ' Bajo mínimo',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            if (producto.categoriaNombre != null)
              Text(producto.categoriaNombre!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (valor) {
            if (valor == 'editar') onEditar();
            if (valor == 'eliminar') onEliminar();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(
              value: 'eliminar',
              child: Text('Desactivar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
