import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/features/busqueda/indice_busqueda.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';

import '../tipos_lugar.dart';
import '../widgets/resultados_busqueda.dart';
import 'zona_detalle_screen.dart';

class ZonasScreen extends StatefulWidget {
  final ZonaRepository repository;
  final AnalyticsAdapter analytics;
  final StaticMapAdapter? staticMap;
  final ValueChanged<String>? onComoLlegar;

  const ZonasScreen({
    super.key,
    required this.repository,
    this.analytics = const AnalyticsAdapterNulo(),
    this.staticMap,
    this.onComoLlegar,
  });

  @override
  State<ZonasScreen> createState() => _ZonasScreenState();
}

class _ZonasScreenState extends State<ZonasScreen> {
  // Se crea una sola vez: si se creara en build(), cada rebuild volvería a
  // leer y parsear zonas.json.
  late Future<List<Zona>> _zonas;

  // El índice del buscador se arma con las zonas ya cargadas, una vez por
  // carga (no en cada tecla).
  IndiceBusqueda? _indice;
  final _consulta = TextEditingController();

  @override
  void initState() {
    super.initState();
    _zonas = _cargar();
  }

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  Future<List<Zona>> _cargar() async {
    final zonas = await widget.repository.obtenerPuntos();
    _indice = IndiceBusqueda(zonas);
    return zonas;
  }

  void _reintentar() {
    setState(() {
      _zonas = _cargar();
    });
  }

  void _abrirDetalle(Zona zona, {String? pisoId, String? espacioId}) {
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
        builder: (_) => ZonaDetalleScreen(
          zona: zona,
          staticMap: widget.staticMap,
          onComoLlegar: widget.onComoLlegar,
          pisoInicialId: pisoId,
          espacioResaltadoId: espacioId,
        ),
      ),
    );
  }

  void _abrirResultado(ResultadoBusqueda resultado) {
    _abrirDetalle(
      resultado.zona,
      pisoId: resultado.piso?.id,
      espacioId: resultado.espacio?.id,
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
        final consulta = _consulta.text;
        final comoLlegar = widget.onComoLlegar;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _CampoBusqueda(
                controller: _consulta,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: consulta.trim().isEmpty
                  ? _ListaZonas(zonas: puntos, onAbrir: _abrirDetalle)
                  : ResultadosBusqueda(
                      consulta: consulta,
                      resultados: _indice?.buscar(consulta) ?? const [],
                      onAbrir: _abrirResultado,
                      onComoLlegar: comoLlegar == null ? null : (r) => comoLlegar(r.zona.id),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _CampoBusqueda({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar zona, espacio o salón',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Borrar búsqueda',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

/// Catálogo de zonas en tarjetas con chip de iniciales (propuesta de
/// interfaz, pantalla 2): el tinte del chip dice qué tipo de lugar es.
class _ListaZonas extends StatelessWidget {
  final List<Zona> zonas;
  final ValueChanged<Zona> onAbrir;
  const _ListaZonas({required this.zonas, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: zonas.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final zona = zonas[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: _ChipIniciales(zona: zona),
            title: Text(zona.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(resumenZona(zona)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onAbrir(zona),
          ),
        );
      },
    );
  }
}

class _ChipIniciales extends StatelessWidget {
  final Zona zona;
  const _ChipIniciales({required this.zona});

  @override
  Widget build(BuildContext context) {
    final estilo = estiloTipo(zona.tipo);
    // Decorativo: el nombre ya está al lado, así que no se lee dos veces.
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: estilo.fondo,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Text(
          inicialesZona(zona.nombre),
          style: TextStyle(color: estilo.texto, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
