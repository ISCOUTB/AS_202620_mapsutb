import 'package:flutter/material.dart';
import 'package:mapsutb/models/zona.dart';

class ZonaDetalleScreen extends StatelessWidget {
  final Zona zona;
  const ZonaDetalleScreen({super.key, required this.zona});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(zona.nombre)),
      body: zona.pisos.isEmpty
          ? const Center(child: Text('Esta zona no tiene pisos registrados.'))
          : ListView.builder(
              itemCount: zona.pisos.length,
              itemBuilder: (context, i) {
                final piso = zona.pisos[i];
                final espacios = zona.espaciosEnPiso(piso.id);

                return ExpansionTile(
                  title: Text(piso.nombre),
                  children: espacios.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Text('Sin espacios registrados en este piso.'),
                          ),
                        ]
                      : espacios.map((espacio) {
                          return ListTile(
                            title: Text(espacio.nombre),
                            subtitle: Text(
                              espacio.salones.isEmpty
                                  ? espacio.tipo
                                  : '${espacio.tipo} — Salones: '
                                      '${espacio.salones.map((s) => s.nombre).join(', ')}',
                            ),
                          );
                        }).toList(),
                );
              },
            ),
    );
  }
}
