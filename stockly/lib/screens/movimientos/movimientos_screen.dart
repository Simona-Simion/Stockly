import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/movimiento_stock.dart';
import '../../services/movimiento_service.dart';

// Historial completo de movimientos de stock: ventas, mermas, entradas y ajustes.
// Se ordena por fecha descendente (el más reciente primero).
class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final MovimientoService _service = MovimientoService();
  List<MovimientoStock> _movimientos = [];
  bool _cargando = true;
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
      _movimientos = await _service.listar();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_movimientos.isEmpty) {
      return const Center(
        child: Text('Sin movimientos', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _movimientos.length,
        itemBuilder: (context, i) => _MovimientoCard(movimiento: _movimientos[i]),
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final MovimientoStock movimiento;

  const _MovimientoCard({required this.movimiento});

  // Configuración visual según el tipo de movimiento
  static const _config = {
    'VENTA': (Icons.point_of_sale, Colors.blue, '-'),
    'MERMA': (Icons.delete, Colors.orange, '-'),
    'ENTRADA': (Icons.add_shopping_cart, Colors.green, '+'),
    'AJUSTE': (Icons.tune, Colors.purple, '±'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[movimiento.tipo] ??
        (Icons.swap_horiz, Colors.grey, '');
    final (icono, color, signo) = cfg;
    final fecha =
        DateFormat('dd/MM/yyyy HH:mm').format(movimiento.fecha.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icono, color: color, size: 20),
        ),
        title: Text(
          movimiento.productoNombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fecha, style: const TextStyle(fontSize: 12)),
            if (movimiento.motivo != null)
              Text(movimiento.motivo!,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$signo${movimiento.cantidad.toStringAsFixed(3)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movimiento.tipo,
                style: TextStyle(fontSize: 10, color: color),
              ),
            ),
          ],
        ),
        isThreeLine: movimiento.motivo != null,
      ),
    );
  }
}
