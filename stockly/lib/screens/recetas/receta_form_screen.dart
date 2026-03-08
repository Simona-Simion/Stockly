import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../providers/receta_provider.dart';

// Formulario para crear una receta con sus ingredientes.
// Se añaden ingredientes dinámicamente: se elige el producto y la cantidad.
class RecetaFormScreen extends StatefulWidget {
  const RecetaFormScreen({super.key});

  @override
  State<RecetaFormScreen> createState() => _RecetaFormScreenState();
}

class _RecetaFormScreenState extends State<RecetaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _precioVenta = TextEditingController();

  // Lista de ingredientes añadidos por el usuario: {productoId, cantidad}
  final List<Map<String, dynamic>> _ingredientes = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Carga los productos para poder elegirlos como ingredientes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precioVenta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>().productos;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva receta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Datos básicos de la receta
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
              validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 20),

            // Sección de ingredientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredientes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _mostrarDialogoIngrediente(context, productos),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),

            // Lista de ingredientes añadidos
            if (_ingredientes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Añade al menos un ingrediente',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._ingredientes.asMap().entries.map((entry) {
                final i = entry.key;
                final ing = entry.value;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.circle, size: 8),
                  title: Text(ing['nombre'] as String),
                  subtitle: Text('${ing['cantidad']} unidades'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        setState(() => _ingredientes.removeAt(i)),
                  ),
                );
              }),

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
              label: const Text('Crear receta'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para elegir un producto y su cantidad como ingrediente
  void _mostrarDialogoIngrediente(BuildContext context, List<Producto> productos) {
    String? productoSeleccionadoId;
    String? productoSeleccionadoNombre;
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir ingrediente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              items: productos
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nombre),
                      ))
                  .toList(),
              onChanged: (v) {
                productoSeleccionadoId = v;
                productoSeleccionadoNombre =
                    productos.firstWhere((p) => p.id == v).nombre;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                hintText: 'ej: 0.05',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final cantidad = double.tryParse(cantidadCtrl.text);
              if (productoSeleccionadoId != null && cantidad != null && cantidad > 0) {
                setState(() {
                  _ingredientes.add({
                    'productoId': productoSeleccionadoId,
                    'nombre': productoSeleccionadoNombre,
                    'cantidad': cantidad,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ingrediente')),
      );
      return;
    }

    setState(() => _guardando = true);

    final body = {
      'nombre': _nombre.text.trim(),
      if (_descripcion.text.isNotEmpty) 'descripcion': _descripcion.text.trim(),
      'precioVenta': double.tryParse(_precioVenta.text) ?? 0,
      'lineas': _ingredientes
          .map((i) => {
                'productoId': i['productoId'],
                'cantidad': i['cantidad'],
              })
          .toList(),
    };

    try {
      await context.read<RecetaProvider>().crear(body);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta creada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
