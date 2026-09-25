import 'dart:math';

import 'package:flutter/material.dart';
import 'adapters/analytics_adapter.dart';
import 'adapters/geocoding_adapter.dart';
import 'adapters/static_map_adapter.dart';
import 'core/config_apis.dart';
import 'features/zonas/presentation/screens/zonas_screen.dart';
import 'features/mapas_ruteo/presentation/screens/ubicacion_screen.dart';
import 'repositories/zona_repository.dart';
import 'services/ubicacion_service.dart';

void main() => runApp(const MapsUtbApp());

class MapsUtbApp extends StatelessWidget {
  const MapsUtbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MAPSUTB',
      home: _RaizNavegacion(),
    );
  }
}

class _RaizNavegacion extends StatefulWidget {
  const _RaizNavegacion();

  @override
  State<_RaizNavegacion> createState() => _RaizNavegacionState();
}

class _RaizNavegacionState extends State<_RaizNavegacion> {
  int _indice = 0;
  late final UbicacionService _ubicacionService;
  late final ZonaRepository _zonaRepository;
  late final AnalyticsAdapter _analytics;
  GeocodingAdapter? _geocoding;
  StaticMapAdapter? _staticMap;

  @override
  void initState() {
    super.initState();
    _ubicacionService = UbicacionServiceSimulado();
    _zonaRepository = ZonaRepositoryLocal();

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
            // Identificador por sesión: sin almacenamiento persistente aún,
            // cada arranque cuenta como un cliente nuevo en GA4.
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

  @override
  Widget build(BuildContext context) {
    final pantalla = _indice == 0
        ? ZonasScreen(
            repository: _zonaRepository,
            analytics: _analytics,
            staticMap: _staticMap,
          )
        : UbicacionScreen(service: _ubicacionService, geocoding: _geocoding);

    return Scaffold(
      appBar: AppBar(title: const Text('MAPSUTB')),
      body: pantalla,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Zonas'),
          NavigationDestination(
              icon: Icon(Icons.my_location), label: 'Ubicación'),
        ],
      ),
    );
  }
}
