import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

// Formulario de alta y edición de producto.
// Si se recibe un producto existente, los campos se precargan con sus datos.
class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _codigoBarras = TextEditingController();
  final _stockActual = TextEditingController();
  final _stockMinimo = TextEditingController();
  final _precioUnidad = TextEditingController();

  // Listas cargadas desde la API para los desplegables
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _unidades = [];
  String? _categoriaId;
  String? _unidadId;

  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _cargarDesplegables();

    // Si estamos editando, precargamos los valores actuales
    if (_esEdicion) {
      final p = widget.producto!;
      _nombre.text = p.nombre;
      _codigoBarras.text = p.codigoBarras ?? '';
      _stockActual.text = p.stockActual.toString();
      _stockMinimo.text = p.stockMinimo.toString();
      _precioUnidad.text = p.precioUnidad?.toString() ?? '';
    }
  }

  // Carga categorías y unidades de medida desde la API para los Dropdowns
  Future<void> _cargarDesplegables() async {
    try {
      final api = ApiService();
      final cats = await api.get(endpointCategorias) as List;
      final unis = await api.get(endpointUnidades) as List;
      setState(() {
        _categorias = cats.cast<Map<String, dynamic>>();
        _unidades = unis.cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // Si falla, los desplegables quedan vacíos — el usuario puede continuar
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigoBarras.dispose();
    _stockActual.dispose();
    _stockMinimo.dispose();
    _precioUnidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _campo(
              controller: _nombre,
              label: 'Nombre *',
              icon: Icons.label_outline,
              validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 12),
            _campo(
              controller: _codigoBarras,
              label: 'Código de barras (EAN-13)',
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    controller: _stockActual,
                    label: 'Stock actual *',
                    icon: Icons.inventory,
                    teclado: TextInputType.number,
                    validator: (v) =>
                        v!.isEmpty ? 'Obligatorio' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    controller: _stockMinimo,
                    label: 'Stock mínimo *',
                    icon: Icons.warning_amber_outlined,
                    teclado: TextInputType.number,
                    validator: (v) =>
                        v!.isEmpty ? 'Obligatorio' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _campo(
              controller: _precioUnidad,
              label: 'Precio unitario (€)',
              icon: Icons.euro,
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Desplegable de categoría
            DropdownButtonFormField<String>(
              initialValue: _categoriaId,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['nombre'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 12),

            // Desplegable de unidad de medida
            DropdownButtonFormField<String>(
              initialValue: _unidadId,
              decoration: const InputDecoration(
                labelText: 'Unidad de medida',
                prefixIcon: Icon(Icons.straighten_outlined),
                border: OutlineInputBorder(),
              ),
              items: _unidades
                  .map((u) => DropdownMenuItem<String>(
                        value: u['id'] as String,
                        child: Text(u['nombre'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _unidadId = v),
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
              label: Text(_esEdicion ? 'Guardar cambios' : 'Crear producto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final body = {
      'nombre': _nombre.text.trim(),
      if (_codigoBarras.text.isNotEmpty) 'codigoBarras': _codigoBarras.text.trim(),
      'stockActual': double.tryParse(_stockActual.text) ?? 0,
      'stockMinimo': double.tryParse(_stockMinimo.text) ?? 0,
      if (_precioUnidad.text.isNotEmpty)
        'precioUnidad': double.tryParse(_precioUnidad.text),
      if (_categoriaId != null) 'categoriaId': _categoriaId,
      if (_unidadId != null) 'unidadMedidaId': _unidadId,
    };

    try {
      final provider = context.read<ProductoProvider>();
      if (_esEdicion) {
        await provider.actualizar(widget.producto!.id, body);
      } else {
        await provider.crear(body);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Producto actualizado' : 'Producto creado'),
          ),
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
