import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../models/proveedor.dart';
import '../../providers/pedido_proveedor_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/proveedor_provider.dart';

class PedidoProveedorFormScreen extends StatefulWidget {
  const PedidoProveedorFormScreen({super.key});

  @override
  State<PedidoProveedorFormScreen> createState() =>
      _PedidoProveedorFormScreenState();
}

class _PedidoProveedorFormScreenState extends State<PedidoProveedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_PedidoLineaForm> _lineas = [_PedidoLineaForm()];

  Proveedor? _proveedorSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorProvider>().cargar();
      context.read<ProductoProvider>().cargar();
    });
  }

  @override
  void dispose() {
    for (final linea in _lineas) {
      linea.dispose();
    }
    super.dispose();
  }

  void _agregarLinea() {
    setState(() => _lineas.add(_PedidoLineaForm()));
  }

  void _eliminarLinea(int index) {
    if (_lineas.length == 1) {
      return;
    }

    final linea = _lineas.removeAt(index);
    linea.dispose();
    setState(() {});
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_proveedorSeleccionado == null) {
      _mostrarError('Selecciona un proveedor');
      return;
    }

    if (_lineas.isEmpty) {
      _mostrarError('Anade al menos una linea');
      return;
    }

    final lineas = _lineas.map<Map<String, dynamic>>((linea) {
      final precioTexto = linea.precioCtrl.text.trim();
      return {
        'productoId': linea.productoSeleccionado!.id,
        'cantidad': _parseNumero(linea.cantidadCtrl.text),
        if (precioTexto.isNotEmpty) 'precioUnitario': _parseNumero(precioTexto),
      };
    }).toList();

    setState(() => _guardando = true);

    try {
      await context.read<PedidoProveedorProvider>().crear(
        proveedorId: _proveedorSeleccionado!.id,
        lineas: lineas,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pedido creado')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  double _parseNumero(String valor) {
    return double.parse(valor.trim().replaceAll(',', '.'));
  }

  String? _validarCantidad(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Introduce la cantidad';
    }

    final cantidad = double.tryParse(valor.trim().replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      return 'Cantidad invalida';
    }

    return null;
  }

  String? _validarPrecio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return null;
    }

    final precio = double.tryParse(valor.trim().replaceAll(',', '.'));
    if (precio == null || precio <= 0) {
      return 'Precio invalido';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo pedido')),
      body: Consumer2<ProveedorProvider, ProductoProvider>(
        builder: (context, proveedorProvider, productoProvider, _) {
          final cargandoInicial =
              (proveedorProvider.cargando &&
                  proveedorProvider.proveedores.isEmpty) ||
              (productoProvider.cargando && productoProvider.productos.isEmpty);

          if (cargandoInicial) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = proveedorProvider.error ?? productoProvider.error;
          if (error != null) {
            return _ErrorPanel(
              mensaje: error,
              onReintentar: () {
                context.read<ProveedorProvider>().cargar();
                context.read<ProductoProvider>().cargar();
              },
            );
          }

          final proveedores = [...proveedorProvider.proveedores]
            ..sort(
              (a, b) =>
                  a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
            );
          final productos =
              productoProvider.productos
                  .where((producto) => producto.activo)
                  .toList()
                ..sort(
                  (a, b) =>
                      a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
                );

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              children: [
                DropdownButtonFormField<Proveedor>(
                  initialValue: _proveedorSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor *',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: proveedores
                      .map(
                        (proveedor) => DropdownMenuItem(
                          value: proveedor,
                          child: Text(proveedor.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: _guardando
                      ? null
                      : (proveedor) =>
                            setState(() => _proveedorSeleccionado = proveedor),
                  validator: (proveedor) =>
                      proveedor == null ? 'Selecciona un proveedor' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lineas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _guardando ? null : _agregarLinea,
                      icon: const Icon(Icons.add),
                      label: const Text('Anadir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._lineas.asMap().entries.map(
                  (entry) => _LineaPedidoCard(
                    index: entry.key,
                    linea: entry.value,
                    productos: productos,
                    puedeEliminar: _lineas.length > 1,
                    guardando: _guardando,
                    validarCantidad: _validarCantidad,
                    validarPrecio: _validarPrecio,
                    onProductoChanged: (producto) {
                      setState(
                        () => entry.value.productoSeleccionado = producto,
                      );
                    },
                    onEliminar: () => _eliminarLinea(entry.key),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Crear pedido'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PedidoLineaForm {
  Producto? productoSeleccionado;
  final cantidadCtrl = TextEditingController();
  final precioCtrl = TextEditingController();

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}

class _LineaPedidoCard extends StatelessWidget {
  final int index;
  final _PedidoLineaForm linea;
  final List<Producto> productos;
  final bool puedeEliminar;
  final bool guardando;
  final String? Function(String?) validarCantidad;
  final String? Function(String?) validarPrecio;
  final ValueChanged<Producto?> onProductoChanged;
  final VoidCallback onEliminar;

  const _LineaPedidoCard({
    required this.index,
    required this.linea,
    required this.productos,
    required this.puedeEliminar,
    required this.guardando,
    required this.validarCantidad,
    required this.validarPrecio,
    required this.onProductoChanged,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Linea ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar linea',
                  onPressed: guardando || !puedeEliminar ? null : onEliminar,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            DropdownButtonFormField<Producto>(
              initialValue: linea.productoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Producto *',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
              ),
              items: productos
                  .map(
                    (producto) => DropdownMenuItem(
                      value: producto,
                      child: Text(producto.nombre),
                    ),
                  )
                  .toList(),
              onChanged: guardando ? null : onProductoChanged,
              validator: (producto) =>
                  producto == null ? 'Selecciona un producto' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: linea.cantidadCtrl,
              enabled: !guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad *',
                prefixIcon: Icon(Icons.add),
                border: OutlineInputBorder(),
              ),
              validator: validarCantidad,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: linea.precioCtrl,
              enabled: !guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio unitario',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
              validator: validarPrecio,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorPanel({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
