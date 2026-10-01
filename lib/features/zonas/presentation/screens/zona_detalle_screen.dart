import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/models/imagen_mapa.dart';
import 'package:mapsutb/models/zona.dart';

class ZonaDetalleScreen extends StatelessWidget {
  final Zona zona;
  final StaticMapAdapter? staticMap;

  /// Si se da, aparece "Cómo llegar": cierra el detalle y pide la ruta a la zona.
  final ValueChanged<String>? onComoLlegar;
  const ZonaDetalleScreen({super.key, required this.zona, this.staticMap, this.onComoLlegar});

  @override
  Widget build(BuildContext context) {
    final adapter = staticMap;
    final comoLlegar = onComoLlegar;

    return Scaffold(
      appBar: AppBar(title: Text(zona.nombre)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (adapter != null && zona.tieneCoordenadas)
            _MiniaturaMapa(zona: zona, adapter: adapter),
          if (comoLlegar != null && zona.tieneCoordenadas)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilledButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: const Text('Cómo llegar'),
                onPressed: () {
                  Navigator.of(context).pop();
                  comoLlegar(zona.id);
                },
              ),
            ),
          Expanded(child: _ListaPisos(zona: zona)),
        ],
      ),
    );
  }
}

class _ListaPisos extends StatelessWidget {
  final Zona zona;
  const _ListaPisos({required this.zona});

  @override
  Widget build(BuildContext context) {
    if (zona.pisos.isEmpty) {
      return const Center(child: Text('Esta zona no tiene pisos registrados.'));
    }
    return ListView.builder(
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
                    child: Text('Sin espacios registrados en este piso.'),
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
    );
  }
}

/// Miniatura estática de la zona vía [StaticMapAdapter] (ADR 0005). Si la
/// llamada falla se muestra un mensaje controlado (Escenario 3).
class _MiniaturaMapa extends StatefulWidget {
  final Zona zona;
  final StaticMapAdapter adapter;
  const _MiniaturaMapa({required this.zona, required this.adapter});

  @override
  State<_MiniaturaMapa> createState() => _MiniaturaMapaState();
}

class _MiniaturaMapaState extends State<_MiniaturaMapa> {
  late final Future<ImagenMapa> _imagen;

  @override
  void initState() {
    super.initState();
    _imagen = widget.adapter.obtenerImagenMapa(
      lat: widget.zona.lat,
      lng: widget.zona.lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: FutureBuilder<ImagenMapa>(
        future: _imagen,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Mapa no disponible.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Image.memory(
            Uint8List.fromList(snapshot.data!.bytesPng),
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
