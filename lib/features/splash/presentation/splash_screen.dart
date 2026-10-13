import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.siguiente});

  /// Pantalla a la que se navega cuando termina la carga.
  final WidgetBuilder siguiente;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _iniciar();
  }

  Future<void> _iniciar() async {
    await Future.wait([
      _cargarDatos(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.siguiente),
    );
  }

  Future<void> _cargarDatos() async {
    // Aquí puedes precargar lo que necesite la app antes de mostrar el home.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF093AD8), // azul institucional UTB
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/mapsutb_logo_WHITE.svg',
                width: 140,
              ),
              const SizedBox(height: 24),
              const Text(
                'MAPS UTB',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color.fromARGB(255, 237, 227, 255),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}