import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pedido_proveedor.dart';
import '../../providers/pedido_proveedor_provider.dart';
import 'pedido_proveedor_detalle_screen.dart';
import 'pedido_proveedor_form_screen.dart';
import '../proveedores/proveedores_screen.dart';

class PedidosProveedorScreen extends StatefulWidget {
  const PedidosProveedorScreen({super.key});

  @override
  State<PedidosProveedorScreen> createState() => _PedidosProveedorScreenState();
}

class _PedidosProveedorScreenState extends State<PedidosProveedorScreen> {
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidoProveedorProvider>().cargar();
    });
  }

  Future<void> _abrirDetalle(String pedidoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedidoProveedorDetalleScreen(pedidoId: pedidoId),
      ),
    );

    if (mounted) {
      context.read<PedidoProveedorProvider>().cargar();
    }
  }

  Future<void> _abrirNuevoPedido() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PedidoProveedorFormScreen()),
    );

    if (mounted) {
      context.read<PedidoProveedorProvider>().cargar();
    }
  }

  Future<void> _abrirProveedores() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
    );

    if (mounted) {
      context.read<PedidoProveedorProvider>().cargar();
    }
  }

  void _seleccionarAccion(_PedidoProveedorAccion accion) {
    switch (accion) {
      case _PedidoProveedorAccion.nuevoPedido:
        _abrirNuevoPedido();
        break;
      case _PedidoProveedorAccion.proveedores:
        _abrirProveedores();
        break;
      case _PedidoProveedorAccion.recargar:
        context.read<PedidoProveedorProvider>().cargar();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos proveedor'),
        actions: [
          PopupMenuButton<_PedidoProveedorAccion>(
            tooltip: 'Acciones',
            onSelected: _seleccionarAccion,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _PedidoProveedorAccion.nuevoPedido,
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Nuevo pedido'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _PedidoProveedorAccion.proveedores,
                child: ListTile(
                  leading: Icon(Icons.business_outlined),
                  title: Text('Proveedores'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _PedidoProveedorAccion.recargar,
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Recargar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PedidoProveedorProvider>(
        builder: (context, provider, _) {
          if (provider.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildError(provider.error!);
          }

          if (provider.pedidos.isEmpty) {
            return const Center(
              child: Text(
                'No hay pedidos',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<PedidoProveedorProvider>().cargar(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.pedidos.length,
              itemBuilder: (context, index) {
                final pedido = provider.pedidos[index];
                return _PedidoCard(
                  pedido: pedido,
                  fecha: _formatoFecha.format(pedido.fecha.toLocal()),
                  onTap: () => _abrirDetalle(pedido.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<PedidoProveedorProvider>().cargar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

enum _PedidoProveedorAccion { nuevoPedido, proveedores, recargar }

class _PedidoCard extends StatelessWidget {
  final PedidoProveedor pedido;
  final String fecha;
  final VoidCallback onTap;

  const _PedidoCard({
    required this.pedido,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(pedido.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.receipt_long_outlined, color: color),
        ),
        title: Text(
          pedido.proveedorNombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$fecha - ${pedido.lineas.length} lineas'),
        trailing: _EstadoChip(estado: pedido.estado, color: color),
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'RECIBIDO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  final Color color;

  const _EstadoChip({required this.estado, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
