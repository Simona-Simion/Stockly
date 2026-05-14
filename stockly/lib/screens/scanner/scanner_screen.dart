import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/producto.dart';
import '../../services/api_service.dart';
import '../../services/local_database_service.dart';
import '../../services/producto_local_service.dart';
import '../../services/producto_service.dart';
import '../productos/producto_form_screen.dart';
import '../stock/entrada_stock_screen.dart';

// Pantalla de escáner de código de barras.
// Abre la cámara, detecta el código y navega al flujo correspondiente.
// Funciona en móvil nativo y en PWA (navegador con HTTPS o localhost).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  static const Duration _cooldownDeteccion = Duration(seconds: 2);

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final ProductoService _productoService = ProductoService();
  final ProductoLocalService _productoLocalService = ProductoLocalService();

  bool _procesando = false;
  String? _ultimoCodigoDetectado;
  DateTime? _ultimaDeteccion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _debeIgnorarCodigo(String codigo) {
    final ahora = DateTime.now();

    if (_ultimoCodigoDetectado == codigo && _ultimaDeteccion != null) {
      final diferencia = ahora.difference(_ultimaDeteccion!);
      if (diferencia < _cooldownDeteccion) {
        return true;
      }
    }

    _ultimoCodigoDetectado = codigo;
    _ultimaDeteccion = ahora;
    return false;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando || capture.barcodes.isEmpty) {
      return;
    }

    final codigo = capture.barcodes.first.rawValue?.trim();
    if (codigo == null || codigo.isEmpty || _debeIgnorarCodigo(codigo)) {
      return;
    }

    if (mounted) {
      setState(() => _procesando = true);
    }

    await _detenerScannerSeguro();

    try {
      final Producto producto = await _productoService.buscarPorCodigo(codigo);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EntradaStockScreen(productoInicial: producto),
        ),
      );
    } on ApiRequestException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 404) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductoFormScreen(codigoBarrasInicial: codigo),
          ),
        );
        return;
      }

      await _mostrarErrorYReanudar(
        'No se pudo buscar el producto. Inténtalo de nuevo.',
      );
    } catch (_) {
      if (!mounted) return;

      await _buscarLocalOReanudar(codigo);
    }
  }

  Future<void> _buscarLocalOReanudar(String codigo) async {
    if (!LocalDatabaseService.instance.isSupported) {
      await _mostrarErrorYReanudar(
        'No se pudo buscar el producto sin conexión.',
      );
      return;
    }

    try {
      final producto = await _productoLocalService
          .obtenerProductoPorCodigoBarras(codigo);

      if (!mounted) return;

      if (producto != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EntradaStockScreen(productoInicial: producto),
          ),
        );
        return;
      }

      await _mostrarErrorYReanudar(
        'Producto no encontrado en el catálogo local.',
      );
    } catch (_) {
      if (!mounted) return;

      await _mostrarErrorYReanudar('No se pudo buscar el producto en local.');
    }
  }

  Future<void> _detenerScannerSeguro() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Puede estar ya detenido o cerrándose.
    }
  }

  Future<void> _mostrarErrorYReanudar(String mensaje) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    if (mounted) {
      setState(() => _procesando = false);
    }

    if (mounted) {
      try {
        await _controller.start();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear producto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScanOverlay(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta al código de barras del producto',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_procesando)
            const ColoredBox(
              color: Colors.black38,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Overlay semitransparente con recuadro de escaneo en el centro
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const ventana = 260.0;
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(ventana: ventana),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double ventana;
  const _OverlayPainter({required this.ventana});

  @override
  void paint(Canvas canvas, Size size) {
    final oscuro = Paint()..color = Colors.black54;
    final borde = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: ventana,
      height: ventana,
    );

    // Dibuja el fondo oscuro con un hueco en el centro
    final fondo = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(fondo, oscuro);

    // Borde blanco del recuadro
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borde,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
