import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/models/imagen_mapa.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/core/bg_widget.dart';

/// Colores que se alternan entre pisos (color y variante oscura para textos).
const _acentos = <(Color, Color)>[
  (AppColors.azulPrincipal, AppColors.azulPrincipal),
  (AppColors.verdeEsmeralda, AppColors.verdeEsmeralda),
  (AppColors.celeste, AppColors.azulPrincipal),
  (AppColors.verdeLima, AppColors.verdeEsmeralda),
];

class ZonaDetalleScreen extends StatelessWidget {
  final Zona zona;
  final StaticMapAdapter? staticMap;

  /// Si se da, aparece "Cómo llegar": cierra el detalle y pide la ruta a la zona.
  final ValueChanged<String>? onComoLlegar;
  const ZonaDetalleScreen(
      {super.key, required this.zona, this.staticMap, this.onComoLlegar});

  @override
  Widget build(BuildContext context) {
    final adapter = staticMap;
    final comoLlegar = onComoLlegar;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.azulPrincipal,
        title: Text(
          zona.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: AppColors.azulPrincipal,
          ),
        ),
      ),
      body: FondoMenu(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 8, 16, 24),
            children: [
              if (adapter != null && zona.tieneCoordenadas)
                _TarjetaMapa(zona: zona, adapter: adapter),
              if (comoLlegar != null && zona.tieneCoordenadas) ...[
                const SizedBox(height: 16),
                _BotonComoLlegar(
                  onTap: () {
                    Navigator.of(context).pop();
                    comoLlegar(zona.id);
                  },
                ),
              ],
              const SizedBox(height: 24),
              _ListaPisos(zona: zona),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón principal con degradado azul -> celeste.
class _BotonComoLlegar extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonComoLlegar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.azulPrincipal, AppColors.celeste],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulPrincipal.withOpacity(.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_walk, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Cómo llegar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaPisos extends StatelessWidget {
  final Zona zona;
  const _ListaPisos({required this.zona});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              const Text(
                'Pisos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.azulPrincipal,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.verdeLima,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        if (zona.pisos.isEmpty)
          const _MensajeVacio(
            icono: Icons.layers_clear_outlined,
            texto: 'Esta zona no tiene pisos registrados.',
          )
        else
          for (var i = 0; i < zona.pisos.length; i++)
            _TarjetaPiso(zona: zona, indice: i),
      ],
    );
  }
}

class _TarjetaPiso extends StatelessWidget {
  final Zona zona;
  final int indice;
  const _TarjetaPiso({required this.zona, required this.indice});

  @override
  Widget build(BuildContext context) {
    final piso = zona.pisos[indice];
    final espacios = zona.espaciosEnPiso(piso.id);
    final (color, oscuro) = _acentos[indice % _acentos.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Theme(
          // Quita las líneas divisorias por defecto del ExpansionTile.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: oscuro,
            collapsedIconColor: oscuro,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(.65)],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.layers, color: Colors.white, size: 24),
            ),
            title: Text(
              piso.nombre,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1B1F),
              ),
            ),
            subtitle: Text(
              espacios.isEmpty
                  ? 'Sin espacios'
                  : '${espacios.length} '
                      '${espacios.length == 1 ? 'espacio' : 'espacios'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            children: espacios.isEmpty
                ? const [
                    _MensajeVacio(
                      icono: Icons.meeting_room_outlined,
                      texto: 'Sin espacios registrados en este piso.',
                    ),
                  ]
                : [
                    for (final espacio in espacios)
                      _FilaEspacio(
                        nombre: espacio.nombre,
                        tipo: espacio.tipo,
                        salones: espacio.salones.map((s) => s.nombre).toList(),
                        color: color,
                        oscuro: oscuro,
                      ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _FilaEspacio extends StatelessWidget {
  final String nombre;
  final String tipo;
  final List<String> salones;
  final Color color;
  final Color oscuro;

  const _FilaEspacio({
    required this.nombre,
    required this.tipo,
    required this.salones,
    required this.color,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room_outlined, size: 20, color: oscuro),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B1F),
                  ),
                ),
              ),
              _Etiqueta(texto: tipo, color: color, oscuro: oscuro),
            ],
          ),
          if (salones.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in salones)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(.5)),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: oscuro,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color oscuro;
  const _Etiqueta(
      {required this.texto, required this.color, required this.oscuro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: oscuro,
        ),
      ),
    );
  }
}

class _MensajeVacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _MensajeVacio({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icono, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con la miniatura del mapa y la etiqueta del tipo de zona.
class _TarjetaMapa extends StatelessWidget {
  final Zona zona;
  final StaticMapAdapter adapter;
  const _TarjetaMapa({required this.zona, required this.adapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulPrincipal.withOpacity(.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            _MiniaturaMapa(zona: zona, adapter: adapter),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.verdeLima,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zona.tipo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.verdeEsmeralda,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      height: 190,
      width: double.infinity,
      child: FutureBuilder<ImagenMapa>(
        future: _imagen,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      size: 40, color: Colors.grey.shade500),
                  const SizedBox(height: 6),
                  Text(
                    'Mapa no disponible.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: AppColors.azulPrincipal,
              ),
            );
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