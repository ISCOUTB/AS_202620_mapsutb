import 'dart:math';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/core/bg_widget.dart';

import 'package:circular_bottom_navigation/circular_bottom_navigation.dart';
import 'package:circular_bottom_navigation/tab_item.dart';
import 'package:flutter/material.dart';
import '../../../adapters/analytics_adapter.dart';
import '../../../adapters/geocoding_adapter.dart';
import '../../../adapters/static_map_adapter.dart';
import '../../../core/config_apis.dart';
import '../../../repositories/zona_repository.dart';
import '../../../routing/mapa_repository.dart';
import '../../../services/ubicacion_service.dart';
import '../../mapas_ruteo/presentation/screens/mapa_screen.dart';
import '../../mapas_ruteo/presentation/screens/ubicacion_screen.dart';
import '../../zonas/presentation/screens/zonas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;
  late final CircularBottomNavigationController _navController;
  late final UbicacionService _ubicacionService;
  late final ZonaRepository _zonaRepository;
  late final MapaRepository _mapaRepository;
  late final AnalyticsAdapter _analytics;
  String? _destino;
  GeocodingAdapter? _geocoding;
  StaticMapAdapter? _staticMap;

  @override
  void initState() {
    super.initState();
    _navController = CircularBottomNavigationController(_indice);
    _ubicacionService = UbicacionServiceSimulado();
    _zonaRepository = ZonaRepositoryLocal();
    _mapaRepository = MapaRepositoryLocal();

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
    _navController.dispose();
    _ubicacionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle etiqueta(Color c) =>
        TextStyle(color: c, fontWeight: FontWeight.w900);

    final tabs = <TabItem>[
      TabItem(Icons.apartment, 'Zonas', AppColors.iaBlanco,
          labelStyle: etiqueta(const Color.fromARGB(255, 255, 255, 255))),
      TabItem(Icons.map, 'Mapa', AppColors.iaBlanco,
          labelStyle: etiqueta(AppColors.iaBlanco)),
      TabItem(Icons.my_location, 'Ubicación', AppColors.iaBlanco,
          labelStyle: etiqueta(AppColors.iaBlanco)),
    ];

    final pantalla = switch (_indice) {
      0 => ZonasScreen(
          repository: _zonaRepository,
          analytics: _analytics,
          staticMap: _staticMap,
          onComoLlegar: (zonaId) {
            _destino = zonaId;
            // Mueve el círculo y dispara selectedCallback, que actualiza _indice.
            _navController.value = 1;
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
      _ => UbicacionScreen(service: _ubicacionService, geocoding: _geocoding),
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 100,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MAPSUTB',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.azulPrincipal,
          ),
        ),
      ),
      body: FondoMenu(child: SafeArea(child: pantalla)),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      bottomNavigationBar: SafeArea(
        child: CircularBottomNavigation(
          tabs,
          controller: _navController,
          selectedPos: _indice,
          barHeight: 60,
          circleSize: 58,
          barBackgroundColor: AppColors.azulPrincipal,
          selectedIconColor: AppColors.azulPrincipal,
          normalIconColor: const Color.fromARGB(255, 255, 255, 255),
          selectedCallback: (pos) {
            if (pos != null && pos != _indice) {
              setState(() => _indice = pos);
            }
          },
        ),
      ),
    );
  }
}