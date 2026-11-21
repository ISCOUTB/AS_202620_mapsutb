import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/core/texto_ondulante.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.siguiente});

  /// Pantalla que se revela cuando el splash sube.
  final WidgetBuilder siguiente;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ---------- Entrada ----------
  late final AnimationController _entrada;
  late final Animation<double> _fade;
  late final Animation<double> _escalaLogo;
  late final Animation<double> _caidaLogo;

  // ---------- Salida ----------
  late final AnimationController _salida;
  late final Animation<double> _escalaSalida;
  late final Animation<double> _opacidadSalida;
  late final Animation<Offset> _subida;

  bool _mostrarSiguiente = false;
  bool _splashVisible = true;

  @override
  void initState() {
    super.initState();

    // ----- Entrada -----
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(
      parent: _entrada,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _escalaLogo = CurvedAnimation(
      parent: _entrada,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    );
    _caidaLogo = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(
        parent: _entrada,
        curve: const Interval(0.0, 0.7, curve: Curves.bounceOut),
      ),
    );

    // ----- Salida -----
    _salida = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo: se agacha (1 -> 0.85) y salta (0.85 -> 1.25), luego se queda.
    _escalaSalida = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.25)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _salida,
        curve: const Interval(0.0, 0.55),
      ),
    );

    // Texto y loader se desvanecen al inicio de la salida.
    _opacidadSalida = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _salida,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // El splash completo sube, solapado con el salto del logo.
    _subida = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(
      CurvedAnimation(
        parent: _salida,
        curve: const Interval(0.35, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _entrada.forward();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final esTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!esTest) {
      await Future.wait([
        _cargarDatos(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
    } else {
      await _cargarDatos();
    }

    if (!mounted) return;

    // Construye la pantalla siguiente debajo del splash.
    setState(() => _mostrarSiguiente = true);

    // Espera un frame para que se construya antes de animar (evita saltos).
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await _salida.forward();
    if (!mounted) return;

    // Quita el splash del árbol cuando ya salió de pantalla.
    setState(() => _splashVisible = false);
  }

  Future<void> _cargarDatos() async {
    // Aquí puedes precargar lo que necesite la app antes de mostrar el home.
  }

  @override
  void dispose() {
    _entrada.dispose();
    _salida.dispose();
    super.dispose();
  }

  Widget _splash() {
    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_entrada, _salida]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _caidaLogo.value),
                  child: Transform.scale(
                    scale: _escalaLogo.value * _escalaSalida.value,
                    child: child,
                  ),
                );
              },
              child: SvgPicture.asset(
                'assets/icons/mapsutb_logo_WHITE.svg',
                width: 140,
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fade,
              child: FadeTransition(
                opacity: _opacidadSalida,
                child: const TextoOndulante(
                  'MAPS UTB',
                  amplitud: 4,
                  estilo: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fade,
              child: FadeTransition(
                opacity: _opacidadSalida,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color.fromARGB(255, 237, 227, 255),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_mostrarSiguiente) Positioned.fill(child: widget.siguiente(context)),
        if (_splashVisible)
          Positioned.fill(
            child: SlideTransition(
              position: _subida,
              child: _splash(),
            ),
          ),
      ],
    );
  }
}