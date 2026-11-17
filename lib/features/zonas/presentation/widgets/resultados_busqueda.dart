import 'package:flutter/material.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/features/busqueda/indice_busqueda.dart';

import '../tipos_lugar.dart';

/// Resultados del buscador de la pestaña Zonas: qué es cada punto y dónde
/// queda (Zona · Piso). Si la zona tiene coordenadas, cada resultado ofrece
/// "Cómo llegar" sin pasar por el detalle.
///
/// Las filas entran escalonadas (fade + deslizamiento). La animación de
/// salida la hace el AnimatedSwitcher de ZonasScreen al borrar la búsqueda.
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
        child: _EntradaFila(
          indice: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sin resultados para «${consulta.trim()}»',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prueba con el nombre del bloque, del espacio o el número del salón.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: resultados.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _EntradaFila(
        indice: i,
        child: _FilaResultado(
          resultado: resultados[i],
          onAbrir: onAbrir,
          onComoLlegar: onComoLlegar,
        ),
      ),
    );
  }
}

/// Fade + deslizamiento hacia arriba, con retraso según la posición de la
/// fila. Solo las primeras filas se escalonan; las demás entran directo para
/// que no haya espera al hacer scroll.
class _EntradaFila extends StatelessWidget {
  final int indice;
  final Widget child;

  const _EntradaFila({required this.indice, required this.child});

  static const _escalonMs = 55;
  static const _duracionMs = 380;
  static const _maxEscalonadas = 8;

  @override
  Widget build(BuildContext context) {
    final retrasoMs = indice < _maxEscalonadas ? indice * _escalonMs : 0;
    final totalMs = retrasoMs + _duracionMs;
    final curva = Interval(
      retrasoMs / totalMs,
      1.0,
      curve: Curves.easeOutCubic,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      child: child,
      builder: (context, t, hijo) {
        final v = curva.transform(t);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 16),
            child: hijo,
          ),
        );
      },
    );
  }
}

class _FilaResultado extends StatelessWidget {
  final ResultadoBusqueda resultado;
  final ValueChanged<ResultadoBusqueda> onAbrir;
  final ValueChanged<ResultadoBusqueda>? onComoLlegar;

  const _FilaResultado({
    required this.resultado,
    required this.onAbrir,
    this.onComoLlegar,
  });

  @override
  Widget build(BuildContext context) {
    final comoLlegar = onComoLlegar;

    // Icono, texto de "qué es" y color según el tipo de resultado.
    final (icono, queEs, colorIcono) = switch (resultado.tipo) {
      TipoResultado.zona => (
          Icons.apartment,
          etiquetaTipo(resultado.zona.tipo),
          AppColors.azulPrincipal,
        ),
      TipoResultado.espacio => (
          Icons.meeting_room_outlined,
          etiquetaTipo(resultado.espacio!.tipo),
          AppColors.morado,
        ),
      TipoResultado.salon => (
          Icons.door_front_door_outlined,
          resultado.espacio!.nombre,
          AppColors.verdeLima,
        ),
    };

    // Una zona ya dice qué es con su tipo; un espacio o salón dice además dónde.
    final subtitulo = resultado.tipo == TipoResultado.zona
        ? queEs
        : '$queEs · ${resultado.donde}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icono, color: colorIcono),
        title: Text(
          resultado.titulo,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.azulOscuro,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        onTap: () => onAbrir(resultado),
        trailing: comoLlegar != null && resultado.zona.tieneCoordenadas
            ? IconButton(
                icon: const Icon(Icons.directions_walk),
                color: AppColors.azulPrincipal,
                tooltip: 'Cómo llegar',
                onPressed: () => comoLlegar(resultado),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}