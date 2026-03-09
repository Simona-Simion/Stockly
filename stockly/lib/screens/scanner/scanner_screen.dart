import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/producto.dart';
import '../../services/producto_service.dart';
import '../productos/producto_detalle_screen.dart';

// Pantalla de escáner de código de barras.
// Abre la cámara, detecta el código y navega al detalle del producto.
// Funciona en móvil nativo y en PWA (navegador con HTTPS o localhost).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ProductoService _productoService = ProductoService();
  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Ignora detecciones múltiples mientras se procesa una
    if (_procesando) return;

    final codigo = capture.barcodes.firstOrNull?.rawValue;
    if (codigo == null) return;

    setState(() => _procesando = true);
    await _controller.stop();

    try {
      final Producto producto = await _productoService.buscarPorCodigo(codigo);
      if (!mounted) return;

      // Reemplaza la pantalla del escáner por el detalle del producto
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductoDetalleScreen(producto: producto),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto no encontrado para el código: $codigo'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      // Reanuda el escáner para intentar con otro código
      setState(() => _procesando = false);
      await _controller.start();
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
          // Vista de la cámara
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay oscuro con ventana de escaneo
          _ScanOverlay(),

          // Texto de ayuda en la parte inferior
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

          // Indicador de carga mientras se busca el producto
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
