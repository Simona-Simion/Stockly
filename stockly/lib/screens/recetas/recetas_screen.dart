import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/receta.dart';
import '../../providers/receta_provider.dart';
import 'receta_form_screen.dart';

// Elimina decimales innecesarios: 1.000 → "1", 0.070 → "0.07"
String _formatCantidad(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

// Listado de recetas. Cada receta muestra su precio y número de ingredientes.
// Al pulsar sobre una receta se puede ver sus ingredientes completos.
class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});

  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetaProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RecetaProvider>().cargar(),
          ),
        ],
      ),
      body: Consumer<RecetaProvider>(
        builder: (context, provider, _) {
          if (provider.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!),
                  ElevatedButton(
                    onPressed: () => context.read<RecetaProvider>().cargar(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (provider.recetas.isEmpty) {
            return const Center(
              child: Text('No hay recetas', style: TextStyle(color: Colors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<RecetaProvider>().cargar(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.recetas.length,
              itemBuilder: (context, i) =>
                  _RecetaCard(receta: provider.recetas[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecetaFormScreen()),
        ).then((_) => context.read<RecetaProvider>().cargar()),
        icon: const Icon(Icons.add),
        label: const Text('Nueva receta'),
      ),
    );
  }
}

class _RecetaCard extends StatelessWidget {
  final Receta receta;

  const _RecetaCard({required this.receta});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.menu_book,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(
          receta.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          receta.precioVenta != null
              ? '${receta.precioVenta!.toStringAsFixed(2)} €  ·  ${receta.lineas.length} ingredientes'
              : '${receta.lineas.length} ingredientes',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: 'Editar receta',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecetaFormScreen(receta: receta),
            ),
          ).then((_) => context.read<RecetaProvider>().cargar()),
        ),
        // Al expandir se muestran los ingredientes de la receta
        children: receta.lineas.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin ingredientes'),
                ),
              ]
            : receta.lineas
                .map(
                  (l) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 8),
                    title: Text(l.productoNombre),
                    trailing: Text(
                      (l.unidadMedida != null && l.unidadMedida!.isNotEmpty)
                          ? '${_formatCantidad(l.cantidad)} ${l.unidadMedida}'
                          : _formatCantidad(l.cantidad),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
