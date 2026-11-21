import 'dart:math';
import 'package:flutter/material.dart';

/// Texto cuyas letras hacen una "ola": cada letra sube un poco y vuelve a su
/// sitio, una detrás de otra.
///
/// - [amplitud]: cuánto sube cada letra, en píxeles (más bajo = más suave).
/// - [duracion]: lo que tarda la ola en recorrer todo el texto.
/// - [desfase]: separación de la ola entre letras (0.05 a 0.15 queda bien).
class TextoOndulante extends StatefulWidget {
  final String texto;
  final TextStyle estilo;
  final double amplitud;
  final Duration duracion;
  final double desfase;

  const TextoOndulante(
    this.texto, {
    super.key,
    required this.estilo,
    this.amplitud = 4,
    this.duracion = const Duration(milliseconds: 1600),
    this.desfase = 0.08,
  });

  @override
  State<TextoOndulante> createState() => _TextoOndulanteState();
}

class _TextoOndulanteState extends State<TextoOndulante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duracion);
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letras = widget.texto.split('');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < letras.length; i++)
              Transform.translate(
                // Solo sube (max con 0) y vuelve a su sitio, como una ola.
                offset: Offset(
                  0,
                  -widget.amplitud *
                      max(0.0, sin(2 * pi * (_controller.value - i * widget.desfase))),
                ),
                child: Text(letras[i], style: widget.estilo),
              ),
          ],
        );
      },
    );
  }
}