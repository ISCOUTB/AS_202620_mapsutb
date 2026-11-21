import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapsutb/core/ajustes_idioma.dart';
import 'package:mapsutb/core/app_colors.dart';

class _Idioma {
  final Locale locale;
  final String nombre;
  final String traduccion;
  final String sigla;

  const _Idioma(this.locale, this.nombre, this.traduccion, this.sigla);
}

/// Se muestra la primera vez que se abre la app (después del splash).
/// Es obligatoria: el botón no se activa hasta que se elija un idioma.
class SeleccionIdiomaScreen extends StatefulWidget {
  const SeleccionIdiomaScreen({super.key, required this.siguiente});

  /// Pantalla a la que se navega cuando el usuario confirma su idioma.
  final WidgetBuilder siguiente;

  @override
  State<SeleccionIdiomaScreen> createState() => _SeleccionIdiomaScreenState();
}

class _SeleccionIdiomaScreenState extends State<SeleccionIdiomaScreen>
    with TickerProviderStateMixin {
  static const _idiomas = <_Idioma>[
    _Idioma(Locale('es'), 'Español', 'Spanish', 'ES'),
    _Idioma(Locale('en'), 'English', 'Inglés', 'EN'),
    _Idioma(Locale('fr'), 'Français', 'Francés', 'FR'),
  ];

  // ---------- Animación de entrada ----------
  late final AnimationController _intro;
  late final Animation<double> _bienvenido;
  late final Animation<double> _subtitulo;
  late final List<Animation<double>> _opciones;
  late final Animation<double> _boton;

    // ---------- Animación de salida ----------
  late final AnimationController _salida;
  late final Animation<double> _salidaOpacidad;
  late final Animation<Offset> _salidaDesplazamiento;

  Locale? _elegido;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    // "Bienvenido" ocupa el primer tramo de la secuencia.
    _bienvenido = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.42),
    );

    _subtitulo = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.33, 0.58, curve: Curves.easeOut),
    );

    // Cada opción entra un poquito después de la anterior.
    _opciones = List.generate(_idiomas.length, (i) {
      final inicio = (0.52 + i * 0.09).clamp(0.0, 0.75);
      return CurvedAnimation(
        parent: _intro,
        curve: Interval(inicio, inicio + 0.25, curve: Curves.easeOutCubic),
      );
    });

    _boton = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    );

        _salida = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _salidaOpacidad = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _salida, curve: Curves.easeInCubic),
    );

    _salidaDesplazamiento = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.04),
    ).animate(CurvedAnimation(parent: _salida, curve: Curves.easeInOut));

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _salida.dispose();
    super.dispose();
  }

      Future<void> _confirmar() async {
    final idioma = _elegido;
    if (idioma == null || _guardando) return;

    setState(() => _guardando = true);
    await AjustesIdioma.instancia.elegir(idioma);
    if (!mounted) return;

    // 1) El contenido se va suavemente (el fondo se queda).
    await _salida.forward();
    if (!mounted) return;

    // 2) Crossfade largo hacia la siguiente pantalla.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, _, __) => widget.siguiente(context),
        transitionsBuilder: (context, animation, _, child) {
          final curva = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curva,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.03, end: 1.0).animate(curva),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      body: FondoAnimado(
        child: FadeTransition(
          opacity: _salidaOpacidad,
          child:SlideTransition(
            position: _salidaDesplazamiento,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),

                      // ----- Bienvenido (letra por letra + cambio de fuentes) -----
                      Center(
                        child: _TextoPorLetras(
                          texto: 'Bienvenido',
                          animacion: _bienvenido,
                          estilo: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ----- Subtítulo -----
                      _Aparecer(
                        animacion: _subtitulo,
                        desplazamiento: 14,
                        child: Column(
                          children: [
                            const Text(
                              'Antes de empezar, elige tu idioma',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Before we start, choose your language',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(150),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Avant de commencer, choisissez votre langue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ----- Opciones (entran una a una) -----
                      for (var i = 0; i < _idiomas.length; i++)
                        _Aparecer(
                          animacion: _opciones[i],
                          child: _OpcionIdioma(
                            idioma: _idiomas[i],
                            seleccionado: _elegido == _idiomas[i].locale,
                            onTap: () =>
                                setState(() => _elegido = _idiomas[i].locale),
                          ),
                        ),

                      const Spacer(flex: 3),

                      // ----- Botón -----
                      _Aparecer(
                        animacion: _boton,
                        child: SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed:
                                (_elegido == null || _guardando) ? null : _confirmar,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.nlsAzulNavy,
                              disabledBackgroundColor: Colors.white.withAlpha(40),
                              disabledForegroundColor: Colors.white54,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionIdioma extends StatelessWidget {
  final _Idioma idioma;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionIdioma({
    required this.idioma,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radio,
          border: Border.all(
            color: seleccionado ? Colors.white : Colors.transparent,
            width: seleccionado ? 4.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: seleccionado
                  ? const Color.fromARGB(255, 154, 208, 255).withAlpha(110)
                  : Colors.black.withAlpha(50),
              blurRadius: seleccionado ? 20 : 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radio,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: seleccionado
                          ? AppColors.verdeLima
                          : AppColors.azulPrincipal.withAlpha(30),
                    ),
                    child: Text(
                      idioma.sigla,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        color: seleccionado
                            ? AppColors.verdeEsmeralda
                            : AppColors.azulPrincipal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idioma.nombre,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        Text(
                          idioma.traduccion,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    seleccionado
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: seleccionado
                        ? AppColors.azulPrincipal
                        : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets de animación de entrada
// ---------------------------------------------------------------------------

/// Texto donde cada letra entra con un pequeño rebote, una tras otra.
/// Cuando termina la entrada, letras al azar cambian de fuente por un
/// instante (con un pequeño "pop") y luego vuelven a la original.
/// Cada letra vive en un casillero de tamaño fijo, así que al cambiar de
/// fuente las demás letras no se mueven.
class _TextoPorLetras extends StatefulWidget {
  const _TextoPorLetras({
    required this.texto,
    required this.animacion,
    required this.estilo,
  });

  final String texto;
  final Animation<double> animacion;
  final TextStyle estilo;

  @override
  State<_TextoPorLetras> createState() => _TextoPorLetrasState();
}

class _TextoPorLetrasState extends State<_TextoPorLetras> {
  static const _intervalo = Duration(milliseconds: 920); // cada cuánto cambia
  static const _duracionCambio = Duration(milliseconds: 960); // cuánto dura
  static const _duracionPop = Duration(milliseconds: 300); // velocidad del "pop"
  static const _letrasPorCambio = 10; // cuántas letras cambian a la vez
  static const _acento = Color(0xFFEDE3FF); // lila del loader del splash

  /// Margen extra del casillero respecto al ancho de la letra original.
  /// 1.0 = espaciado idéntico al original (las fuentes anchas se reducen).
  /// Más alto = más espacio para las fuentes anchas, pero letras angostas
  /// como la "i" quedan con más aire.
  static const _holgura = 1.3;

  final _azar = math.Random();
  Timer? _timer;

  late final List<int> _fuentePorLetra; // 0 = fuente original
  late final List<TextStyle> _variantes;

  // Tamaño fijo del casillero de cada letra (se calcula al inicio).
  List<double> _anchos = const [];
  double _alto = 0;

  @override
  void initState() {
    super.initState();
    _fuentePorLetra = List.filled(widget.texto.length, 0);

    _variantes = [
      widget.estilo, // 0 = original
      widget.estilo.copyWith(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: _acento,
      ),
      widget.estilo.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
        color: _acento,
      ),
      widget.estilo.copyWith(
        fontFamily: 'cursive',
        fontWeight: FontWeight.w500,
        color: _acento,
      ),
      widget.estilo.copyWith(
        fontWeight: FontWeight.w200,
        fontStyle: FontStyle.italic,
        color: _acento,
      ),
    ];

    widget.animacion.addListener(_alAnimar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _medirLetras(MediaQuery.textScalerOf(context));
  }

  /// Mide cada letra con todas las fuentes para reservarle un casillero fijo.
  void _medirLetras(TextScaler escala) {
    final anchos = <double>[];
    var alto = 0.0;

    for (final letra in widget.texto.split('')) {
      var anchoMax = 0.0;
      var anchoBase = 0.0;

      for (var v = 0; v < _variantes.length; v++) {
        final tp = TextPainter(
          text: TextSpan(text: letra, style: _variantes[v]),
          textDirection: TextDirection.ltr,
          textScaler: escala,
        )..layout();

        if (v == 0) anchoBase = tp.width;
        anchoMax = math.max(anchoMax, tp.width);
        alto = math.max(alto, tp.height);
        tp.dispose();
      }

      anchos.add(math.min(anchoMax, anchoBase * _holgura));
    }

    _anchos = anchos;
    _alto = alto;
  }

  /// Espera a que "Bienvenido" termine de entrar para empezar a cambiar.
  void _alAnimar() {
    if (_timer != null || widget.animacion.value < 1.0) return;
    widget.animacion.removeListener(_alAnimar);
    _timer = Timer.periodic(_intervalo, (_) => _cambiarLetrasAlAzar());
  }

  void _cambiarLetrasAlAzar() {
    if (!mounted) return;

    for (var k = 0; k < _letrasPorCambio; k++) {
      final i = _azar.nextInt(_fuentePorLetra.length);
      if (_fuentePorLetra[i] != 0) continue; // ya está cambiada

      final fuente = 1 + _azar.nextInt(_variantes.length - 1);
      setState(() => _fuentePorLetra[i] = fuente);

      // Después de un rato vuelve a la fuente original.
      Future.delayed(_duracionCambio, () {
        if (!mounted) return;
        setState(() => _fuentePorLetra[i] = 0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.animacion.removeListener(_alAnimar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letras = widget.texto.split('');

    return AnimatedBuilder(
      animation: widget.animacion,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < letras.length; i++)
              _letra(letras[i], i, letras.length),
          ],
        );
      },
    );
  }

  Widget _letra(String letra, int i, int total) {
    // Cada letra tiene su propio tramo; se solapan para que fluya.
    final inicio = (i / total) * 0.6;
    final fin = inicio + 0.4;
    final t = Interval(inicio, fin, curve: Curves.easeOutBack)
        .transform(widget.animacion.value);

    final fuente = _fuentePorLetra[i];

    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 32),
        // Casillero fijo: lo de adentro puede cambiar sin mover a las demás.
        child: SizedBox(
          width: _anchos[i],
          height: _alto,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedSwitcher(
              duration: _duracionPop,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                letra,
                key: ValueKey(fuente),
                style: _variantes[fuente],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aparece con fade + deslizamiento suave hacia arriba.
/// Mientras no se ve, ignora los toques.
class _Aparecer extends StatelessWidget {
  const _Aparecer({
    required this.animacion,
    required this.child,
    this.desplazamiento = 24,
  });

  final Animation<double> animacion;
  final Widget child;
  final double desplazamiento;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacion,
      child: child,
      builder: (context, child) {
        final t = animacion.value;
        return IgnorePointer(
          ignoring: t < 0.5,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * desplazamiento),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo animado
// ---------------------------------------------------------------------------

/// Fondo con degradado de [AppColors.azulOscuro] y halos de luz que flotan
/// lentamente. Se puede reutilizar en otras pantallas envolviendo su contenido.
class FondoAnimado extends StatefulWidget {
  const FondoAnimado({super.key, required this.child});

  final Widget child;

  @override
  State<FondoAnimado> createState() => _FondoAnimadoState();
}

class _FondoAnimadoState extends State<FondoAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24), // más alto = más lento
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _OrbesPainter(_controller.value),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Orbe {
  final double cx, cy; // centro (fracción de la pantalla)
  final double ax, ay; // amplitud del movimiento
  final int fx, fy; // vueltas por ciclo (enteros = bucle sin cortes)
  final double fase;
  final double radio; // fracción del ancho de pantalla
  final Color color;
  final int alfa;

  const _Orbe({
    required this.cx,
    required this.cy,
    required this.ax,
    required this.ay,
    required this.fx,
    required this.fy,
    required this.fase,
    required this.radio,
    required this.color,
    required this.alfa,
  });
}

class _OrbesPainter extends CustomPainter {
  _OrbesPainter(this.t);

  final double t; // 0..1

  static const _orbes = <_Orbe>[
    _Orbe(
      cx: 0.2, cy: 0.18, ax: 0.15, ay: 0.08, fx: 1, fy: 2, fase: 0.0,
      radio: 0.75, color: AppColors.azulPrincipal, alfa: 150,
    ),
    _Orbe(
      cx: 0.85, cy: 0.35, ax: 0.12, ay: 0.12, fx: 2, fy: 1, fase: 0.3,
      radio: 0.6, color: Color(0xFF8E7CFF), alfa: 110,
    ),
    _Orbe(
      cx: 0.3, cy: 0.7, ax: 0.18, ay: 0.1, fx: 1, fy: 1, fase: 0.6,
      radio: 0.7, color: AppColors.azulPrincipal, alfa: 120,
    ),
    _Orbe(
      cx: 0.8, cy: 0.9, ax: 0.1, ay: 0.08, fx: 2, fy: 3, fase: 0.85,
      radio: 0.55, color: Color(0xFFEDE3FF), alfa: 60,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Degradado base con el azul oscuro.
    final oscuro = Color.lerp(AppColors.azulOscuro, Colors.black, 0.35)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.azulOscuro, oscuro],
        ).createShader(rect),
    );

    // Halos de luz en movimiento.
    for (final o in _orbes) {
      const ang = 2 * math.pi;
      final x = size.width * (o.cx + o.ax * math.sin(ang * (o.fx * t + o.fase)));
      final y = size.height * (o.cy + o.ay * math.cos(ang * (o.fy * t + o.fase)));
      final r = size.width * o.radio;
      final centro = Offset(x, y);

      canvas.drawCircle(
        centro,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [o.color.withAlpha(o.alfa), o.color.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: centro, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbesPainter old) => old.t != t;
}