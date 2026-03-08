import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/movimiento_stock.dart';
import '../../models/producto.dart';
import '../../services/movimiento_service.dart';
import 'producto_form_screen.dart';

// Ficha completa de un producto: datos, indicador de stock y
// historial de movimientos filtrado solo para ese producto.
class ProductoDetalleScreen extends StatefulWidget {
  final Producto producto;

  const ProductoDetalleScreen({super.key, required this.producto});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  final MovimientoService _movimientoService = MovimientoService();
  List<MovimientoStock> _movimientos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    try {
      _movimientos =
          await _movimientoService.listarPorProducto(widget.producto.id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final bajoMinimo = p.bajominimo;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductoFormScreen(producto: p),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta principal con los datos del producto
          _SeccionDatos(producto: p, bajoMinimo: bajoMinimo),
          const SizedBox(height: 16),

          // Indicador visual del nivel de stock
          _IndicadorStock(producto: p),
          const SizedBox(height: 24),

          // Historial de movimientos de este producto
          const Text(
            'Historial de movimientos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildHistorial(),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }
    if (_movimientos.isEmpty) {
      return const Text(
        'Sin movimientos registrados',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Column(
      children: _movimientos
          .map((m) => _MovimientoItem(movimiento: m))
          .toList(),
    );
  }
}

// Tarjeta con todos los campos del producto
class _SeccionDatos extends StatelessWidget {
  final Producto producto;
  final bool bajoMinimo;

  const _SeccionDatos({required this.producto, required this.bajoMinimo});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: bajoMinimo
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (bajoMinimo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Stock por debajo del mínimo',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            _fila('Nombre', producto.nombre),
            if (producto.categoriaNombre != null)
              _fila('Categoría', producto.categoriaNombre!),
            if (producto.unidadMedidaNombre != null)
              _fila('Unidad de medida', producto.unidadMedidaNombre!),
            if (producto.codigoBarras != null)
              _fila('Código de barras', producto.codigoBarras!),
            if (producto.precioUnidad != null)
              _fila('Precio unitario',
                  '${producto.precioUnidad!.toStringAsFixed(2)} €'),
            _fila('Estado', producto.activo ? 'Activo' : 'Inactivo'),
          ],
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              etiqueta,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Barra visual del nivel de stock actual respecto al mínimo
class _IndicadorStock extends StatelessWidget {
  final Producto producto;

  const _IndicadorStock({required this.producto});

  @override
  Widget build(BuildContext context) {
    // La barra llega al 100% cuando el stock dobla el mínimo
    final referencia = producto.stockMinimo * 2;
    final porcentaje =
        referencia > 0 ? (producto.stockActual / referencia).clamp(0.0, 1.0) : 1.0;
    final bajoMinimo = producto.bajominimo;
    final color = bajoMinimo ? Colors.red : Colors.green;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Stock actual',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  producto.stockActual.toStringAsFixed(3),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mínimo: ${producto.stockMinimo.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Fila compacta para cada movimiento en el historial
class _MovimientoItem extends StatelessWidget {
  final MovimientoStock movimiento;

  const _MovimientoItem({required this.movimiento});

  static const _colores = {
    'VENTA': Colors.blue,
    'MERMA': Colors.orange,
    'ENTRADA': Colors.green,
    'AJUSTE': Colors.purple,
  };

  static const _iconos = {
    'VENTA': Icons.point_of_sale,
    'MERMA': Icons.delete,
    'ENTRADA': Icons.add_shopping_cart,
    'AJUSTE': Icons.tune,
  };

  static const _signo = {
    'VENTA': '-',
    'MERMA': '-',
    'ENTRADA': '+',
    'AJUSTE': '±',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colores[movimiento.tipo] ?? Colors.grey;
    final icono = _iconos[movimiento.tipo] ?? Icons.swap_horiz;
    final signo = _signo[movimiento.tipo] ?? '';
    final fecha = DateFormat('dd/MM/yy HH:mm').format(movimiento.fecha.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        leading: Icon(icono, color: color, size: 20),
        title: Text(
          movimiento.motivo ?? movimiento.tipo,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(fecha, style: const TextStyle(fontSize: 11)),
        trailing: Text(
          '$signo${movimiento.cantidad.toStringAsFixed(3)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
