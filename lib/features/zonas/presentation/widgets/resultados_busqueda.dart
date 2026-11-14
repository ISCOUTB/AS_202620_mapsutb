import 'package:flutter/material.dart';
import 'package:mapsutb/features/busqueda/indice_busqueda.dart';

import '../tipos_lugar.dart';

/// Resultados del buscador de la pestaña Zonas: qué es cada punto y dónde
/// queda (Zona · Piso). Si la zona tiene coordenadas, cada resultado ofrece
/// "Cómo llegar" sin pasar por el detalle.
class ResultadosBusqueda extends StatelessWidget {
  final String consulta;
  final List<ResultadoBusqueda> resultados;
  final ValueChanged<ResultadoBusqueda> onAbrir;
  final ValueChanged<ResultadoBusqueda>? onComoLlegar;

  const ResultadosBusqueda({
    super.key,
    required this.consulta,
    required this.resultados,
    required this.onAbrir,
    this.onComoLlegar,
  });

  @override
  Widget build(BuildContext context) {
    if (resultados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sin resultados para «${consulta.trim()}»',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Prueba con el nombre del bloque, del espacio o el número del salón.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: resultados.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _FilaResultado(
        resultado: resultados[i],
        onAbrir: onAbrir,
        onComoLlegar: onComoLlegar,
      ),
    );
  }
}

class _FilaResultado extends StatelessWidget {
  final ResultadoBusqueda resultado;
  final ValueChanged<ResultadoBusqueda> onAbrir;
  final ValueChanged<ResultadoBusqueda>? onComoLlegar;

  const _FilaResultado({required this.resultado, required this.onAbrir, this.onComoLlegar});

  @override
  Widget build(BuildContext context) {
    final comoLlegar = onComoLlegar;
    final (icono, queEs) = switch (resultado.tipo) {
      TipoResultado.zona => (Icons.apartment, etiquetaTipo(resultado.zona.tipo)),
      TipoResultado.espacio => (Icons.meeting_room_outlined, etiquetaTipo(resultado.espacio!.tipo)),
      TipoResultado.salon => (Icons.door_front_door_outlined, resultado.espacio!.nombre),
    };
    // Una zona ya dice qué es con su tipo; un espacio o salón dice además dónde.
    final subtitulo = resultado.tipo == TipoResultado.zona ? queEs : '$queEs · ${resultado.donde}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icono, color: Theme.of(context).colorScheme.primary),
        title: Text(resultado.titulo),
        subtitle: Text(subtitulo),
        onTap: () => onAbrir(resultado),
        trailing: comoLlegar != null && resultado.zona.tieneCoordenadas
            ? IconButton(
                icon: const Icon(Icons.directions_walk),
                tooltip: 'Cómo llegar',
                onPressed: () => comoLlegar(resultado),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
