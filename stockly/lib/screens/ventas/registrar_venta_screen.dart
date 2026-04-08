import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/receta.dart';
import '../../providers/receta_provider.dart';
import '../../services/venta_service.dart';

// Pantalla para registrar una venta aplicando el escandallo automático.
// El camarero elige la receta y la cantidad. El backend descuenta el stock.
class RegistrarVentaScreen extends StatefulWidget {
  const RegistrarVentaScreen({super.key});

  @override
  State<RegistrarVentaScreen> createState() => _RegistrarVentaScreenState();
}

class _RegistrarVentaScreenState extends State<RegistrarVentaScreen> {
  final VentaService _ventaService = VentaService();

  Receta? _recetaSeleccionada;
  int _cantidad = 1;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetaProvider>().cargar();
    });
  }

  String _formatearCantidad(double cantidad) {
      if (cantidad == cantidad.roundToDouble()) {
        return cantidad.toInt().toString();
      }
      return cantidad.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

  @override
  Widget build(BuildContext context) {
    final recetas = context.watch<RecetaProvider>().recetas;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de receta
            const Text('Receta',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Receta>(
              initialValue: _recetaSeleccionada,
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
      ),
    );
  }

  Future<void> _registrarVenta() async {
    if (_recetaSeleccionada == null) return;

    // Diálogo de confirmación con resumen de ingredientes a descontar
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
}
