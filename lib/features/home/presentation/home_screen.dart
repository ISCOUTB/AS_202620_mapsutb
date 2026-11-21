import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/core/bg_widget.dart';
import 'package:mapsutb/core/barra_navegacion.dart';

import '../../../adapters/analytics_adapter.dart';
import '../../../adapters/geocoding_adapter.dart';
import '../../../adapters/static_map_adapter.dart';
import '../../../core/config_apis.dart';
import '../../../repositories/zona_repository.dart';
import '../../../routing/mapa_repository.dart';
import '../../../services/ubicacion_service.dart';
import '../../../services/ubicacion_service_gps.dart';
import '../../configuracion/presentation/screens/configuracion_screen.dart';
import '../../mapas_ruteo/presentation/screens/mapa_screen.dart';
import '../../zonas/presentation/screens/zonas_screen.dart';

const _ubicacionSimulada = bool.fromEnvironment('UBICACION_SIMULADA');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;
  late final UbicacionService _ubicacionService;
  late final ZonaRepository _zonaRepository;
  late final MapaRepository _mapaRepository;
  late final AnalyticsAdapter _analytics;
  String? _destino;
  StaticMapAdapter? _staticMap;
  GeocodingAdapter? _geocoding;

  @override
  void initState() {
    super.initState();
    _ubicacionService = _ubicacionSimulada
        ? UbicacionServiceSimulado()
        : UbicacionServiceGps();
    _zonaRepository = ZonaRepositoryLocal();
    _mapaRepository = MapaRepositoryLocal();
    // El grafo se lee al arrancar, junto con las zonas que pide la primera
    // pantalla: así una pestaña no combina zonas de una versión con el grafo
    // de un despliegue posterior (arc42 §8, consistencia entre archivos).
    _mapaRepository.obtenerGrafo().ignore();

    // Sin credenciales (--dart-define, ver ConfigApis) la app arranca igual
    // y solo se ocultan las funciones que dependen de cada API.
    if (ConfigApis.tieneGoogleMaps) {
      _geocoding = GeocodingAdapterHttp(apiKey: ConfigApis.googleMapsApiKey);
      _staticMap = StaticMapAdapterHttp(apiKey: ConfigApis.googleMapsApiKey);
    }
    _analytics = ConfigApis.tieneAnalytics
        ? AnalyticsAdapterHttp(
            measurementId: ConfigApis.gaMeasurementId,
            apiSecret: ConfigApis.gaApiSecret,
            clientId: '${Random.secure().nextInt(1 << 31)}'
                '.${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          )
        : const AnalyticsAdapterNulo();
  }

  @override
  void dispose() {
    _ubicacionService.dispose();
    super.dispose();
  }

  /// "Sábado, 14 de noviembre" (requiere initializeDateFormatting('es') en main).
  String _fechaHoy() {
    final texto = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final pantalla = switch (_indice) {
      0 => ZonasScreen(
          repository: _zonaRepository,
          analytics: _analytics,
          staticMap: _staticMap,
          onComoLlegar: (zonaId) {
            setState(() {
              _destino = zonaId;
              _indice = 1;
            });
          },
        ),
      1 => MapaScreen(
          key: ValueKey(_destino),
          zonaRepository: _zonaRepository,
          mapaRepository: _mapaRepository,
          ubicacionService: _ubicacionService,
          destinoInicial: _destino,
          analytics: _analytics,
        ),
      _ => const ConfiguracionScreen(),
    };

    return Scaffold(
      extendBody: true, // el contenido pasa por detrás de la barra inferior
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 80,
        centerTitle: false,
        titleSpacing: 20,
        backgroundColor: AppColors.azulPrincipal,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // iconos blancos arriba
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fechaHoy(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'MAPSUTB',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: FondoMenu(
        child: SafeArea(
          top: false, // el AppBar ya cubre la parte de arriba
          bottom: false, // el contenido llega hasta abajo, detrás de la barra
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            // La key distingue una pantalla de otra para que se anime el cambio.
            child: KeyedSubtree(
              key: ValueKey('$_indice-$_destino'),
              child: pantalla,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BarraNavegacion(
        indice: _indice,
        onSeleccion: (pos) => setState(() => _indice = pos),
      ),
    );
  }
}