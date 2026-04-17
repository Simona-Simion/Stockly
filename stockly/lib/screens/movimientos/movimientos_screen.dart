import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/movimiento_stock.dart';
import '../../services/movimiento_service.dart';

String _formatCantidad(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _formatFechaHora(DateTime fecha) {
  return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toLocal());
}

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => MovimientosScreenState();
}

class MovimientosScreenState extends State<MovimientosScreen> {
  final MovimientoService _service = MovimientoService();
  List<MovimientoStock> _movimientos = [];
  bool _cargando = true;
  String? _error;

  void recargar() => _cargar();

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
      final movimientos = await _service.listar();
      movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));

      if (!mounted) return;
      setState(() {
        _movimientos = movimientos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
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
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) {
      return const _MovimientosEstado(
        icon: Icons.history,
        mensaje: 'Cargando movimientos...',
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _MovimientosEstado(
        icon: Icons.error_outline,
        mensaje: _error!,
        color: Colors.red,
        action: ElevatedButton.icon(
          onPressed: _cargar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }

    if (_movimientos.isEmpty) {
      return const _MovimientosEstado(
        icon: Icons.inventory_2_outlined,
        mensaje: 'No hay movimientos registrados',
        color: Colors.grey,
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _movimientos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) =>
            _MovimientoCard(movimiento: _movimientos[i]),
      ),
    );
  }
}

class _MovimientosEstado extends StatelessWidget {
  final Widget? child;
  final IconData icon;
  final String mensaje;
  final Color? color;
  final Widget? action;

  const _MovimientosEstado({
    this.child,
    required this.icon,
    required this.mensaje,
    this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (child != null) ...[
              child!,
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: resolvedColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: resolvedColor, size: 28),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color == Colors.grey ? Colors.grey.shade700 : null,
                fontSize: 15,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MovimientoVisualConfig {
  final IconData icono;
  final Color color;
  final String signo;
  final String etiqueta;

  const _MovimientoVisualConfig({
    required this.icono,
    required this.color,
    required this.signo,
    required this.etiqueta,
  });
}

class _MovimientoCard extends StatelessWidget {
  final MovimientoStock movimiento;

  const _MovimientoCard({required this.movimiento});

  static const _config = {
    'VENTA': _MovimientoVisualConfig(
      icono: Icons.point_of_sale,
      color: Colors.blue,
      signo: '-',
      etiqueta: 'Venta',
    ),
    'MERMA': _MovimientoVisualConfig(
      icono: Icons.delete_outline,
      color: Colors.orange,
      signo: '-',
      etiqueta: 'Merma',
    ),
    'ENTRADA': _MovimientoVisualConfig(
      icono: Icons.south_west,
      color: Colors.green,
      signo: '+',
      etiqueta: 'Entrada',
    ),
    'AJUSTE': _MovimientoVisualConfig(
      icono: Icons.tune,
      color: Colors.purple,
      signo: '±',
      etiqueta: 'Ajuste',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[movimiento.tipo] ??
        const _MovimientoVisualConfig(
          icono: Icons.swap_horiz,
          color: Colors.grey,
          signo: '',
          etiqueta: 'Movimiento',
        );

    final detalles = <String>[
      _formatFechaHora(movimiento.fecha),
      if (movimiento.origen != null && movimiento.origen!.trim().isNotEmpty)
        movimiento.origen!.replaceAll('_', ' '),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cfg.icono, color: cfg.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cfg.etiqueta,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _TipoChip(
                        texto: movimiento.tipo,
                        color: cfg.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movimiento.productoNombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detalles.join(' . '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (movimiento.motivo != null &&
                      movimiento.motivo!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      movimiento.motivo!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${cfg.signo}${_formatCantidad(movimiento.cantidad)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cfg.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  final String texto;
  final Color color;

  const _TipoChip({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
