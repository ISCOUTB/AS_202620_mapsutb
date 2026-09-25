import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import 'zona_detalle_screen.dart';

class ZonasScreen extends StatefulWidget {
  final ZonaRepository repository;
  final AnalyticsAdapter analytics;
  final StaticMapAdapter? staticMap;

  const ZonasScreen({
    super.key,
    required this.repository,
    this.analytics = const AnalyticsAdapterNulo(),
    this.staticMap,
  });

  @override
  State<ZonasScreen> createState() => _ZonasScreenState();
}

class _ZonasScreenState extends State<ZonasScreen> {
  // Se crea una sola vez: si se creara en build(), cada rebuild volvería a
  // leer y parsear zonas.json.
  late Future<List<Zona>> _zonas;

  @override
  void initState() {
    super.initState();
    _zonas = widget.repository.obtenerPuntos();
  }

  void _reintentar() {
    setState(() => _zonas = widget.repository.obtenerPuntos());
  }

  void _abrirDetalle(Zona zona) {
    // Mejor esfuerzo: un error de analítica nunca interrumpe la navegación
    // (Escenario 3, ADR 0005).
    widget.analytics
        .registrarEvento(EventoAnalitica(
          nombre: 'consulta_zona',
          parametros: {'zona_id': zona.id},
        ))
        .ignore();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ZonaDetalleScreen(zona: zona, staticMap: widget.staticMap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Zona>>(
      future: _zonas,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudieron cargar las zonas.'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _reintentar,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
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
              onTap: () => _abrirDetalle(punto),
            );
          },
        );
      },
    );
  }
}
