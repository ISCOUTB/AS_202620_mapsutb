import 'package:flutter/material.dart';
import 'features/zonas/zonas_screen.dart';
import 'repositories/zona_repository.dart';

void main() => runApp(const MapsUtbApp());

class MapsUtbApp extends StatelessWidget {
  const MapsUtbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAPSUTB',
      home: ZonasScreen(repository: ZonaRepositoryLocal()),
    );
  }
}
