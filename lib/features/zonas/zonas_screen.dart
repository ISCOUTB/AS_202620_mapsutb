import 'package:flutter/material.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import '../../models/zona.dart';
import '../../repositories/zona_repository.dart';

class ZonasScreen extends StatelessWidget {
  final ZonaRepository repository;
  const ZonasScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zonas del campus')),
      body: FutureBuilder<List<Zona>>(
        future: repository.obtenerPuntos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final puntos = snapshot.data!;
          return ListView.builder(
            itemCount: puntos.length,
            itemBuilder: (context, i) {
              final punto = puntos[i];
              return ListTile(
                title: Text(punto.nombre),
                subtitle: Text(punto.tipo),
                // Si el punto tiene pisos, aquí luego se podría navegar
                // a una pantalla de "Piso 1", "Piso 2"... usando punto.pisos
                // y punto.espaciosEnPiso(pisoId).
              );
            },
          );
        },
      ),
    );
  }
}
