import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapsutb/core/app_colors.dart';

/// Fondo para el menú principal: base clara con círculos de degradado radial
/// difuminados (azules y violetas) con la paleta de la app.
///
/// Uso:
/// ```dart
/// Scaffold(body: FondoMenu(child: tuContenido))
/// ```
class FondoMenu extends StatelessWidget {
  final Widget? child;

  /// Color de la base (blanco por defecto).
  final Color fondo;

  /// Opacidad de los círculos: 1.0 = intensidad plena, 0.3 = muy suave.
  final double opacidad;

  /// Desenfoque extra de los círculos (0 = solo degradado radial).
  final double desenfoque;

  const FondoMenu({
    super.key,
    this.child,
    this.fondo = Colors.white,
    this.opacidad = 1.0,
    this.desenfoque = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fondo),
        IgnorePointer(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;

                Widget circulo({
                  required double dx, // centro en X (0..1 del ancho)
                  required double dy, // centro en Y (0..1 del alto)
                  required double diametro, // relativo al ancho
                  required Color color,
                  required int alpha,
                }) {
                  final d = w * diametro;
                  return Positioned(
                    left: w * dx - d / 2,
                    top: h * dy - d / 2,
                    width: d,
                    height: d,
                    child: _Circulo(
                      color: color,
                      alpha: (alpha * opacidad).round().clamp(0, 255),
                    ),
                  );
                }

                Widget circulos = Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Azules
                    circulo(dx: 0.05, dy: 0.05, diametro: 1.1, color: AppColors.azulPrincipal, alpha: 110),
                    circulo(dx: 1.00, dy: 0.28, diametro: 0.9, color: AppColors.celeste, alpha: 100),
                    circulo(dx: 0.10, dy: 0.62, diametro: 0.8, color: AppColors.celeste, alpha: 70),
                    circulo(dx: 0.85, dy: 0.95, diametro: 1.2, color: AppColors.azulPrincipal, alpha: 100),
                    // Violetas
                    circulo(dx: 0.80, dy: 0.02, diametro: 0.7, color: AppColors.morado, alpha: 100),
                    circulo(dx: 0.30, dy: 0.40, diametro: 0.9, color: AppColors.morado, alpha: 80),
                    circulo(dx: 0.00, dy: 1.00, diametro: 0.9, color: AppColors.morado, alpha: 110),
                    // Toque sutil de acento
                    circulo(dx: 0.70, dy: 0.62, diametro: 0.45, color: AppColors.verdeLima, alpha: 35),
                  ],
                );

                if (desenfoque > 0) {
                  circulos = ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: desenfoque,
                      sigmaY: desenfoque,
                      tileMode: TileMode.decal,
                    ),
                    child: circulos,
                  );
                }
                return circulos;
              },
            ),
          ),
        ),
        // Capa blanca translúcida para mantener el fondo claro
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(90),
                  Colors.white.withAlpha(140),
                ],
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

/// Un círculo con degradado radial que se desvanece a transparente.
class _Circulo extends StatelessWidget {
  final Color color;
  final int alpha;

  const _Circulo({required this.color, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withAlpha(alpha),
            color.withAlpha((alpha * 0.45).round()),
            color.withAlpha(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}