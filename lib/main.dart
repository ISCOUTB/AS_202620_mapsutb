import 'package:flutter/material.dart';

/// Punto de entrada del esqueleto de MAPSUTB (monolito).
///
/// Este archivo NO contiene lógica de negocio. Su único propósito es
/// demostrar que el proyecto arranca y que la organización por patrones
/// de diseño (adapters / repositories / strategies / services / features)
/// definida en docs/adr/0001-patrones-de-diseno.md compila y ejecuta.
void main() {
  runApp(const MapsUtbApp());
}

class MapsUtbApp extends StatelessWidget {
  const MapsUtbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAPSUTB',
      home: Scaffold(
        appBar: AppBar(title: const Text('MAPSUTB — esqueleto de arquitectura')),
        body: const Center(
          child: Text(
            'Esqueleto ejecutable (monolito, mapa local, ruteo aproximado).\n'
            'Módulos: tour · mapas_ruteo · realidad_aumentada · zonas',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
