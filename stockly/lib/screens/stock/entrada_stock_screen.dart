import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../repositories/entrada_stock_repository.dart';

class EntradaStockScreen extends StatefulWidget {
  final Producto? productoInicial;

  const EntradaStockScreen({super.key, this.productoInicial});

  @override
  State<EntradaStockScreen> createState() => _EntradaStockScreenState();
}

class _EntradaStockScreenState extends State<EntradaStockScreen> {
  final EntradaStockRepository _entradaStockRepository =
      EntradaStockRepository();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController(text: 'Reposición manual');
  final _formKey = GlobalKey<FormState>();

  Producto? _productoSeleccionado;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProductoProvider>();
      await provider.cargar();

      if (!mounted || widget.productoInicial == null) {
        return;
      }

      final productoActualizado = _buscarProductoPorId(
        provider.productos,
        widget.productoInicial!.id,
      );

      if (productoActualizado != null &&
          _productoSeleccionado?.id == widget.productoInicial!.id) {
        setState(() => _productoSeleccionado = productoActualizado);
      }
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) {
      return cantidad.toInt().toString();
    }
    return cantidad
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Producto? _buscarProductoPorId(List<Producto> productos, String id) {
    for (final producto in productos) {
      if (producto.id == id) {
        return producto;
      }
    }

    return null;
  }

  List<Producto> _productosConSeleccionActual(List<Producto> productos) {
    final seleccionado = _productoSeleccionado;

    if (seleccionado == null ||
        _buscarProductoPorId(productos, seleccionado.id) != null ||
        !seleccionado.activo) {
      return productos;
    }

    return [seleccionado, ...productos];
  }

  @override
  Widget build(BuildContext context) {
    final productosProvider = context
        .watch<ProductoProvider>()
        .productos
        .where((p) => p.activo)
        .toList();
    final productos = _productosConSeleccionActual(productosProvider);
    final productoSeleccionado = _productoSeleccionado == null
        ? null
        : _buscarProductoPorId(productos, _productoSeleccionado!.id);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrada de stock')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Producto>(
                  key: ValueKey(productoSeleccionado?.id ?? 'sin-producto'),
                  initialValue: productoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Producto *',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: productos
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p, child: Text(p.nombre)),
                      )
                      .toList(),
                  onChanged: _registrando
                      ? null
                      : (p) => setState(() => _productoSeleccionado = p),
                  validator: (v) => v == null ? 'Selecciona un producto' : null,
                ),
                const SizedBox(height: 16),
                if (productoSeleccionado != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.green,
                      ),
                      title: Text(productoSeleccionado.nombre),
                      subtitle: Text(
                        'Stock actual: '
                        '${_formatearCantidad(productoSeleccionado.stockActual)}'
                        '${productoSeleccionado.unidadMedidaNombre != null ? ' ${productoSeleccionado.unidadMedidaNombre}' : ''}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _cantidadCtrl,
                  enabled: !_registrando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad *',
                    prefixIcon: Icon(Icons.add),
                    border: OutlineInputBorder(),
                    hintText: 'ej: 10.5',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce la cantidad';
                    }

                    final cantidad = double.tryParse(
                      v.trim().replaceAll(',', '.'),
                    );
                    if (cantidad == null || cantidad <= 0) {
                      return 'Cantidad inválida';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _motivoCtrl,
                  enabled: !_registrando,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    prefixIcon: Icon(Icons.comment_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'ej: Reposición manual',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _registrando ? null : _registrarEntrada,
                    icon: _registrando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: const Text('Registrar entrada'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registrarEntrada() async {
    if (!_formKey.currentState!.validate() || _productoSeleccionado == null) {
      return;
    }

    setState(() => _registrando = true);

    try {
      final cantidad = double.parse(
        _cantidadCtrl.text.trim().replaceAll(',', '.'),
      );
      final motivo = _motivoCtrl.text.trim();

      await _entradaStockRepository.registrarEntradaProducto(
        productoId: _productoSeleccionado!.id,
        cantidad: cantidad,
        motivo: motivo.isEmpty ? 'Reposición manual' : motivo,
      );

      if (mounted) {
        _cantidadCtrl.clear();
        _motivoCtrl.text = 'Reposición manual';
        setState(() => _productoSeleccionado = null);
        await context.read<ProductoProvider>().cargar();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada registrada. Stock actualizado.'),
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
      if (mounted) {
        setState(() => _registrando = false);
      }
    }
  }
}
