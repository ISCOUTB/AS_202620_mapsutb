import 'package:flutter/material.dart';
import 'features/zonas/presentation/screens/zonas_screen.dart';
import 'features/mapas_ruteo/presentation/screens/ubicacion_screen.dart';
import 'repositories/zona_repository.dart';
import 'services/ubicacion_service.dart';

void main() => runApp(const MapsUtbApp());

class MapsUtbApp extends StatelessWidget {
  const MapsUtbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAPSUTB',
      home: const _RaizNavegacion(),
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

  @override
  void initState() {
    super.initState();
    _ubicacionService = UbicacionServiceSimulado();
    _zonaRepository = ZonaRepositoryLocal();
  }

  @override
  void dispose() {
    _ubicacionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantalla = _indice == 0
        ? ZonasScreen(repository: _zonaRepository)
        : UbicacionScreen(service: _ubicacionService);

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
