import 'package:flutter/material.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import '../../../../../models/zona.dart';
import 'zona_detalle_screen.dart';

class ZonasScreen extends StatelessWidget {
  final ZonaRepository repository;
  const ZonasScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Zona>>(
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
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ZonaDetalleScreen(zona: punto),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
