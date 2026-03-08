import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../services/merma_service.dart';

// Pantalla para registrar una merma: producto roto, caducado, derramado, etc.
// Descuenta stock y registra el motivo en el historial.
class RegistrarMermaScreen extends StatefulWidget {
  const RegistrarMermaScreen({super.key});

  @override
  State<RegistrarMermaScreen> createState() => _RegistrarMermaScreenState();
}

class _RegistrarMermaScreenState extends State<RegistrarMermaScreen> {
  final MermaService _mermaService = MermaService();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Producto? _productoSeleccionado;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>().productos;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar merma')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explicación breve para el camarero
              Card(
                color: Colors.orange.shade50,
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text(
                    'Registra producto roto, caducado o derramado. '
                    'El stock se descontará automáticamente.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de producto
              DropdownButtonFormField<Producto>(
                initialValue: _productoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Producto *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
                items: productos
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Text(p.nombre),
                              const SizedBox(width: 8),
                              Text(
                                '(stock: ${p.stockActual.toStringAsFixed(2)})',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (p) => setState(() => _productoSeleccionado = p),
                validator: (v) => v == null ? 'Selecciona un producto' : null,
              ),
              const SizedBox(height: 16),

              // Cantidad a descontar
              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  hintText: 'ej: 0.5',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce la cantidad';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Cantidad inválida';
                  if (_productoSeleccionado != null &&
                      n > _productoSeleccionado!.stockActual) {
                    return 'Supera el stock disponible (${_productoSeleccionado!.stockActual})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Motivo (obligatorio para el historial)
              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo *',
                  prefixIcon: Icon(Icons.comment_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'ej: Botella rota, caducado, derramado...',
                ),
                validator: (v) => v!.isEmpty ? 'Indica el motivo' : null,
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _registrando ? null : _registrarMerma,
                  icon: _registrando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.delete),
                  label: const Text('Registrar merma'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registrarMerma() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _registrando = true);
    try {
      await _mermaService.registrar(
        _productoSeleccionado!.id,
        double.parse(_cantidadCtrl.text),
        _motivoCtrl.text.trim(),
      );
      if (mounted) {
        // Limpia el formulario y recarga el stock
        setState(() => _productoSeleccionado = null);
        _cantidadCtrl.clear();
        _motivoCtrl.clear();
        context.read<ProductoProvider>().cargar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merma registrada. Stock actualizado.'),
            backgroundColor: Colors.orange,
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
}
