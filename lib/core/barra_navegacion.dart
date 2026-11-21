import 'package:flutter/material.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/l10n/app_localizations.dart';

class BarraNavegacion extends StatelessWidget {
  final int indice;
  final ValueChanged<int> onSeleccion;

  const BarraNavegacion({
    super.key,
    required this.indice,
    required this.onSeleccion,
  });

  static const _duracion = Duration(milliseconds: 320);
  static const _curva = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_ItemBarra>[
      _ItemBarra(Icons.apartment_rounded, l10n.navZonas),
      _ItemBarra(Icons.map_rounded, l10n.navMapa),
      _ItemBarra(Icons.settings_rounded, l10n.navConfiguracion),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.azulPrincipal, AppColors.nlsAzulNavy],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.azulOscuro.withAlpha(70),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final ancho = c.maxWidth / items.length;

            return Stack(
              children: [
                // Píldora blanca que se desliza entre los botones.
                AnimatedPositioned(
                  duration: _duracion,
                  curve: _curva,
                  left: ancho * indice,
                  top: 0,
                  bottom: 0,
                  width: ancho,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _BotonBarra(
                          item: items[i],
                          activo: i == indice,
                          onTap: () {
                            if (i != indice) onSeleccion(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemBarra {
  final IconData icono;
  final String etiqueta;
  const _ItemBarra(this.icono, this.etiqueta);
}

class _BotonBarra extends StatelessWidget {
  final _ItemBarra item;
  final bool activo;
  final VoidCallback onTap;

  const _BotonBarra({
    required this.item,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.azulPrincipal : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // El color del icono hace fade y el icono activo crece un poco.
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: BarraNavegacion._duracion,
            curve: BarraNavegacion._curva,
            builder: (context, c, _) => AnimatedScale(
              scale: activo ? 1.12 : 1.0,
              duration: BarraNavegacion._duracion,
              curve: Curves.easeOutBack,
              child: Icon(item.icono, size: 24, color: c),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: BarraNavegacion._duracion,
              curve: BarraNavegacion._curva,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: activo ? FontWeight.w900 : FontWeight.w600,
              ),
              child: Text(item.etiqueta),
            ),
          ),
        ],
      ),
    );
  }
}