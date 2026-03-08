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
                              '${(l.cantidad * _cantidad).toStringAsFixed(3)} ${l.unidadMedida ?? ''}',
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
    setState(() => _registrando = true);
    try {
      await _ventaService.registrar(_recetaSeleccionada!.id, _cantidad);
      if (mounted) {
        // Limpia la selección tras registrar la venta
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
            // El backend devuelve mensajes claros como "Stock insuficiente de Ron"
            content:
                Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }
}
