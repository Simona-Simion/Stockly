import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/producto_provider.dart';
import '../../services/local_database_service.dart';
import '../../services/operacion_local_service.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, required this.nombreUsuario});

  final String nombreUsuario;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final OperacionLocalService _operacionLocalService = OperacionLocalService();

  int? _operacionesPendientes;
  bool _operacionesDisponibles = true;

  @override
  void initState() {
    super.initState();
    _cargarOperacionesPendientes();
  }

  Future<void> _cargarOperacionesPendientes() async {
    if (!LocalDatabaseService.instance.isSupported) {
      if (mounted) {
        setState(() {
          _operacionesPendientes = null;
          _operacionesDisponibles = false;
        });
      }
      return;
    }

    try {
      final operaciones = await _operacionLocalService
          .listarPendientesOrdenadas();

      if (mounted) {
        setState(() {
          _operacionesPendientes = operaciones.length;
          _operacionesDisponibles = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _operacionesPendientes = null;
          _operacionesDisponibles = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = widget.nombreUsuario.trim();

    return RefreshIndicator(
      onRefresh: _cargarOperacionesPendientes,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                nombre.isEmpty ? 'Bienvenido a Stockly' : 'Hola, $nombre',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen de tu inventario',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Consumer<ProductoProvider>(
                builder: (context, provider, _) {
                  final productos = provider.productos;
                  final productosSinStock = productos
                      .where((producto) => producto.stockActual <= 0)
                      .length;
                  final productosDisponibles =
                      provider.error == null || productos.isNotEmpty;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final anchoCard = constraints.maxWidth >= 560
                          ? (constraints.maxWidth - 24) / 3
                          : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ResumenCard(
                            ancho: anchoCard,
                            icono: Icons.inventory_2_outlined,
                            titulo: 'Productos',
                            valor: productosDisponibles
                                ? productos.length.toString()
                                : 'N/D',
                            detalle: 'Registrados',
                            color: theme.colorScheme.primary,
                          ),
                          _ResumenCard(
                            ancho: anchoCard,
                            icono: Icons.remove_shopping_cart_outlined,
                            titulo: 'Sin stock',
                            valor: productosDisponibles
                                ? productosSinStock.toString()
                                : 'N/D',
                            detalle: 'Revisar reposicion',
                            color: Colors.red,
                          ),
                          _ResumenCard(
                            ancho: anchoCard,
                            icono: Icons.sync_problem_outlined,
                            titulo: 'Pendientes',
                            valor: _operacionesDisponibles
                                ? (_operacionesPendientes ?? 0).toString()
                                : 'N/D',
                            detalle: _operacionesDisponibles
                                ? 'Por sincronizar'
                                : 'No disponible',
                            color: Colors.orange,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.ancho,
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.color,
  });

  final double ancho;
  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: ancho,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icono, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
