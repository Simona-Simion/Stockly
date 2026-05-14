import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pedido_proveedor.dart';
import '../../models/pedido_proveedor_linea.dart';
import '../../providers/alerta_provider.dart';
import '../../providers/pedido_proveedor_provider.dart';
import '../../providers/producto_provider.dart';

class PedidoProveedorDetalleScreen extends StatefulWidget {
  final String pedidoId;

  const PedidoProveedorDetalleScreen({super.key, required this.pedidoId});

  @override
  State<PedidoProveedorDetalleScreen> createState() =>
      _PedidoProveedorDetalleScreenState();
}

class _PedidoProveedorDetalleScreenState
    extends State<PedidoProveedorDetalleScreen> {
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  PedidoProveedor? _pedido;
  bool _cargando = true;
  bool _recibiendo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pedido = await context.read<PedidoProveedorProvider>().obtener(
        widget.pedidoId,
      );

      if (!mounted) return;
      setState(() {
        _pedido = pedido;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  double get _totalEstimado {
    final pedido = _pedido;
    if (pedido == null) return 0;

    return pedido.lineas.fold<double>(0, (total, linea) {
      final precio = linea.precioUnitario;
      if (precio == null) return total;
      return total + (linea.cantidad * precio);
    });
  }

  bool get _tienePrecios {
    final pedido = _pedido;
    if (pedido == null) return false;
    return pedido.lineas.any((linea) => linea.precioUnitario != null);
  }

  Future<void> _confirmarRecepcion() async {
    final pedido = _pedido;
    if (pedido == null || !pedido.pendiente || _recibiendo) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recibir pedido'),
        content: const Text('¿Recibir este pedido y sumar stock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Recibir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _recibirPedido(pedido.id);
    }
  }

  Future<void> _recibirPedido(String pedidoId) async {
    if (_recibiendo) {
      return;
    }

    setState(() => _recibiendo = true);

    try {
      final pedidoActualizado = await context
          .read<PedidoProveedorProvider>()
          .recibir(pedidoId);

      if (!mounted) {
        return;
      }

      setState(() => _pedido = pedidoActualizado);

      await context.read<ProductoProvider>().cargar();
      if (!mounted) {
        return;
      }

      await context.read<AlertaProvider>().cargar();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido recibido. Stock actualizado.')),
      );
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
      if (mounted) {
        setState(() => _recibiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle pedido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final pedido = _pedido;
    if (pedido == null) {
      return const Center(child: Text('Pedido no encontrado'));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PedidoResumenCard(
            pedido: pedido,
            fecha: _formatoFecha.format(pedido.fecha.toLocal()),
          ),
          if (pedido.pendiente) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _recibiendo ? null : _confirmarRecepcion,
              icon: _recibiendo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory_2_outlined),
              label: Text(_recibiendo ? 'Recibiendo...' : 'Recibir pedido'),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Lineas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...pedido.lineas.map((linea) => _LineaPedidoCard(linea: linea)),
          if (_tienePrecios) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text(
                  'Total estimado',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '${_totalEstimado.toStringAsFixed(2)} EUR',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PedidoResumenCard extends StatelessWidget {
  final PedidoProveedor pedido;
  final String fecha;

  const _PedidoResumenCard({required this.pedido, required this.fecha});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(pedido.estado);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pedido.proveedorNombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _EstadoChip(estado: pedido.estado, color: color),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.event_outlined, text: fecha),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.format_list_bulleted,
              text: '${pedido.lineas.length} lineas',
            ),
          ],
        ),
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

class _LineaPedidoCard extends StatelessWidget {
  final PedidoProveedorLinea linea;

  const _LineaPedidoCard({required this.linea});

  @override
  Widget build(BuildContext context) {
    final precio = linea.precioUnitario;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(
          linea.productoNombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Cantidad: ${_formatearNumero(linea.cantidad)}'),
        trailing: precio == null
            ? null
            : Text(
                '${precio.toStringAsFixed(2)} EUR',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  String _formatearNumero(double valor) {
    if (valor == valor.roundToDouble()) {
      return valor.toStringAsFixed(0);
    }
    return valor.toStringAsFixed(2);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
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
