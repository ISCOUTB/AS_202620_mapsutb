import 'package:flutter/material.dart';
import 'package:mapsutb/core/app_colors.dart';

/// Fondo para el menú principal: base blanca con bloques geométricos
/// (rectángulos y formas en L) pegados a los bordes, con la paleta de la app.
///
/// Uso:
/// ```dart
/// Scaffold(body: FondoMenu(child: tuContenido))
/// ```
class FondoMenu extends StatelessWidget {
  final Widget? child;

  /// Color de la base (blanco por defecto).
  final Color fondo;

  /// Opacidad de los bloques: 1.0 = color pleno, 0.3 = muy suave.
  final double opacidad;

  const FondoMenu({
    super.key,
    this.child,
    this.fondo = Colors.white,
    this.opacidad = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fondo),
        RepaintBoundary(
          child: CustomPaint(painter: _BloquesPainter(opacidad)),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _BloquesPainter extends CustomPainter {
  final double opacidad;

  const _BloquesPainter(this.opacidad);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = w / 11; // unidad base: grosor de cada bloque

    Paint pintura(Color c) => Paint()..color = c.withOpacity(opacidad);
    final celeste = pintura(AppColors.celeste);
    final lima = pintura(AppColors.verdeLima);
    final azul = pintura(AppColors.azulPrincipal);
    final esmeralda = pintura(AppColors.verdeEsmeralda);

    // ---------- Parte superior ----------
    // Rectángulo celeste flotante.
    canvas.drawRect(Rect.fromLTWH(w * 0.32, u * 0.6, u * 2.2, u), celeste);
    // Rectángulo verde lima que cuelga del borde superior.
    canvas.drawRect(Rect.fromLTWH(w * 0.62, 0, u, u * 1.4), lima);
    // Forma en L azul en la esquina superior derecha.
    canvas.drawRect(Rect.fromLTWH(w - u * 1.7, 0, u, u * 2.4), azul);
    canvas.drawRect(Rect.fromLTWH(w - u * 1.7, u * 1.4, u * 1.7, u), azul);

    // ---------- Laterales ----------
    // Cuadrado azul pegado al borde izquierdo.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.34, u, u), azul);
    // Rectángulo verde lima pegado al borde derecho.
    canvas.drawRect(Rect.fromLTWH(w - u * 1.35, h * 0.60, u * 1.35, u), lima);

    // ---------- Parte inferior ----------
    // Forma en L celeste en la esquina inferior izquierda.
    final yL = h * 0.80;
    canvas.drawRect(Rect.fromLTWH(0, yL, u * 1.85, u), celeste);
    canvas.drawRect(Rect.fromLTWH(u * 0.85, yL + u, u, u * 1.4), celeste);
    // Bloque esmeralda con muesca, abajo a la derecha.
    canvas.drawRect(
        Rect.fromLTWH(w - u * 3, h - u * 1.2, u * 3, u * 0.9), esmeralda);
    canvas.drawRect(
        Rect.fromLTWH(w - u * 3, h - u * 0.3, u * 0.85, u * 0.3), esmeralda);
    canvas.drawRect(
        Rect.fromLTWH(w - u * 0.8, h - u * 0.3, u * 0.8, u * 0.3), esmeralda);
  }

  @override
  bool shouldRepaint(covariant _BloquesPainter old) =>
      old.opacidad != opacidad;
}