import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/receta.dart';
import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../providers/receta_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

// Formulario para crear o editar una receta con sus ingredientes.
// Si se recibe una receta existente, los campos se precargan para edición.
// Cada línea de ingrediente muestra: [Producto ▼] [Cantidad] [Unidad ▼] [🗑]
class RecetaFormScreen extends StatefulWidget {
  final Receta? receta;

  const RecetaFormScreen({super.key, this.receta});

  @override
  State<RecetaFormScreen> createState() => _RecetaFormScreenState();
}

class _RecetaFormScreenState extends State<RecetaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _precioVenta = TextEditingController();

  // Cada ingrediente: productoId, cantidadCtrl, unidadMedidaId
  final List<Map<String, dynamic>> _lineas = [];
  final List<TextEditingController> _cantidadCtrls = [];

  List<Map<String, dynamic>> _unidades = [];
  bool _guardando = false;

  bool get _esEdicion => widget.receta != null;

  @override
  void initState() {
    super.initState();

    // Precargar campos si es edición
    if (_esEdicion) {
      final r = widget.receta!;
      _nombre.text = r.nombre;
      _descripcion.text = r.descripcion ?? '';
      _precioVenta.text = r.precioVenta?.toString() ?? '';
      for (final linea in r.lineas) {
        _lineas.add({
          'productoId': linea.productoId,
          'unidadMedidaId': linea.unidadMedidaId,
        });
        _cantidadCtrls.add(
          TextEditingController(text: linea.cantidad.toString()),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargar();
    });
    _cargarUnidades();
  }

  Future<void> _cargarUnidades() async {
    try {
      final data = await ApiService().get(endpointUnidades) as List;
      if (mounted) {
        setState(() => _unidades = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
    } catch (_) {}
  }

  void _addLinea() {
    setState(() {
      _lineas.add({'productoId': null, 'unidadMedidaId': null});
      _cantidadCtrls.add(TextEditingController());
    });
  }

  void _removeLinea(int i) {
    setState(() {
      _cantidadCtrls[i].dispose();
      _cantidadCtrls.removeAt(i);
      _lineas.removeAt(i);
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precioVenta.dispose();
    for (final ctrl in _cantidadCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>().productos;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar receta' : 'Nueva receta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre de la receta *',
                prefixIcon: Icon(Icons.menu_book_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioVenta,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio de venta (€) *',
                prefixIcon: Icon(Icons.euro),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obligatorio';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Debe ser > 0';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Cabecera ingredientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredientes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _addLinea,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),

            if (_lineas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Añade al menos un ingrediente',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...List.generate(
                _lineas.length,
                (i) => _buildLineaRow(i, productos),
              ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_esEdicion ? 'Guardar cambios' : 'Crear receta'),
            ),
          ],
        ),
      ),
    );
  }

  // Fila por ingrediente: [Producto ▼] [Cantidad] [Unidad ▼] [🗑]
  Widget _buildLineaRow(int i, List<Producto> productos) {
    // Guarda contra valores que aún no están en la lista cargada
    final productoId = _lineas[i]['productoId'] as String?;
    final unidadId = _lineas[i]['unidadMedidaId'] as String?;
    final validProductoId =
        productos.any((p) => p.id == productoId) ? productoId : null;
    final validUnidadId =
        _unidades.any((u) => u['id'] == unidadId) ? unidadId : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown producto
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: validProductoId,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: productos
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _lineas[i]['productoId'] = v),
              validator: (_) =>
                  _lineas[i]['productoId'] == null ? 'Elige un producto' : null,
            ),
          ),
          const SizedBox(width: 8),

          // Campo cantidad
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _cantidadCtrls[i],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obligatorio';
                if ((double.tryParse(v) ?? 0) <= 0) return 'Inválido';
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),

          // Dropdown unidad de medida
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: validUnidadId,
              decoration: const InputDecoration(
                labelText: 'Unidad',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('— sin unidad —'),
                ),
                ..._unidades.map((u) => DropdownMenuItem<String>(
                      value: u['id'] as String,
                      child: Text(
                        u['nombre'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (v) =>
                  setState(() => _lineas[i]['unidadMedidaId'] = v),
            ),
          ),

          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeLinea(i),
            tooltip: 'Eliminar ingrediente',
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un ingrediente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final body = {
      'nombre': _nombre.text.trim(),
      if (_descripcion.text.isNotEmpty) 'descripcion': _descripcion.text.trim(),
      'precioVenta': double.tryParse(_precioVenta.text) ?? 0,
      'lineas': List.generate(_lineas.length, (i) => {
        'productoId': _lineas[i]['productoId'],
        'cantidad': double.tryParse(_cantidadCtrls[i].text) ?? 0,
        if (_lineas[i]['unidadMedidaId'] != null)
          'unidadMedidaId': _lineas[i]['unidadMedidaId'],
      }),
    };

    try {
      final provider = context.read<RecetaProvider>();
      if (_esEdicion) {
        await provider.actualizar(widget.receta!.id, body);
      } else {
        await provider.crear(body);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion ? 'Receta actualizada' : 'Receta creada correctamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
