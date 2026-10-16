import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/models/espacio.dart';
import 'package:mapsutb/models/imagen_mapa.dart';
import 'package:mapsutb/models/zona.dart';

import '../tipos_lugar.dart';

class ZonaDetalleScreen extends StatelessWidget {
  final Zona zona;
  final StaticMapAdapter? staticMap;

  /// Si se da, aparece "Cómo llegar": cierra el detalle y pide la ruta a la zona.
  final ValueChanged<String>? onComoLlegar;

  /// Piso que se muestra al abrir (por ejemplo, desde el buscador). Si no
  /// se da o no existe en la zona, se muestra el primero.
  final String? pisoInicialId;

  /// Espacio que se resalta y se lleva a la vista al abrir (buscador).
  final String? espacioResaltadoId;

  const ZonaDetalleScreen({
    super.key,
    required this.zona,
    this.staticMap,
    this.onComoLlegar,
    this.pisoInicialId,
    this.espacioResaltadoId,
  });

  @override
  Widget build(BuildContext context) {
    final adapter = staticMap;
    final comoLlegar = onComoLlegar;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(zona.nombre)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (adapter != null && zona.tieneCoordenadas)
            _MiniaturaMapa(zona: zona, adapter: adapter),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              resumenZona(zona),
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
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
          Expanded(
            child: _EspaciosPorPiso(
              zona: zona,
              pisoInicialId: pisoInicialId,
              espacioResaltadoId: espacioResaltadoId,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de piso en píldoras + espacios del piso elegido (propuesta de
/// interfaz, pantalla 3). Los espacios que no caen en ningún piso no se
/// esconden: en una zona sin pisos (Zona T, Quid) se listan directamente, y
/// en una con pisos aparecen bajo "Otros espacios".
class _EspaciosPorPiso extends StatefulWidget {
  final Zona zona;
  final String? pisoInicialId;
  final String? espacioResaltadoId;
  const _EspaciosPorPiso({required this.zona, this.pisoInicialId, this.espacioResaltadoId});

  @override
  State<_EspaciosPorPiso> createState() => _EspaciosPorPisoState();
}

class _EspaciosPorPisoState extends State<_EspaciosPorPiso> {
  /// Valor del selector para el grupo de espacios sin piso.
  static const _sinPiso = '';

  late String _seleccion;
  final _claveResaltado = GlobalKey();

  Zona get _zona => widget.zona;

  @override
  void initState() {
    super.initState();
    _seleccion = _seleccionInicial();
    if (widget.espacioResaltadoId != null) {
      // Tras el primer frame la tarjeta ya existe y se puede llevar a la vista.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final contexto = _claveResaltado.currentContext;
        if (contexto != null && contexto.mounted) {
          Scrollable.ensureVisible(contexto, alignment: 0.1);
        }
      });
    }
  }

  String _seleccionInicial() {
    final pisos = _zona.pisos;
    if (pisos.any((p) => p.id == widget.pisoInicialId)) return widget.pisoInicialId!;
    if (_zona.espaciosSinPiso.any((e) => e.id == widget.espacioResaltadoId)) return _sinPiso;
    return pisos.isEmpty ? _sinPiso : pisos.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final sinPiso = _zona.espaciosSinPiso;
    if (_zona.pisos.isEmpty && sinPiso.isEmpty) {
      return const Center(child: Text('Esta zona no tiene espacios registrados.'));
    }

    final espacios = _seleccion == _sinPiso ? sinPiso : _zona.espaciosEnPiso(_seleccion);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_zona.pisos.isNotEmpty)
          _SelectorPiso(
            opciones: {
              for (final piso in _zona.pisos) piso.id: piso.nombre,
              if (sinPiso.isNotEmpty) _sinPiso: 'Otros espacios',
            },
            seleccion: _seleccion,
            onSeleccion: (id) => setState(() => _seleccion = id),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Espacios', style: Theme.of(context).textTheme.titleMedium),
          ),
        Expanded(
          child: espacios.isEmpty
              ? const Center(child: Text('Sin espacios registrados en este piso.'))
              // Columna y no ListView.builder: son pocos espacios por piso y
              // así la tarjeta resaltada existe para llevarla a la vista.
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final espacio in espacios)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TarjetaEspacio(
                            key: espacio.id == widget.espacioResaltadoId ? _claveResaltado : null,
                            espacio: espacio,
                            resaltado: espacio.id == widget.espacioResaltadoId,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Píldoras de piso: la elegida en azul con texto blanco (8,1:1), el resto
/// blancas con borde fino (propuesta de interfaz, componente "floor").
class _SelectorPiso extends StatelessWidget {
  final Map<String, String> opciones;
  final String seleccion;
  final ValueChanged<String> onSeleccion;
  const _SelectorPiso({required this.opciones, required this.seleccion, required this.onSeleccion});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (final MapEntry(key: id, value: nombre) in opciones.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(nombre),
                selected: id == seleccion,
                onSelected: (_) => onSeleccion(id),
                showCheckmark: false,
                backgroundColor: esquema.surface,
                selectedColor: esquema.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: id == seleccion ? esquema.onPrimary : esquema.onSurfaceVariant,
                ),
                side: BorderSide(color: id == seleccion ? esquema.primary : esquema.outlineVariant),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca de un espacio: nombre, etiqueta de tipo y sus salones
/// como chips pequeños.
class _TarjetaEspacio extends StatelessWidget {
  final Espacio espacio;
  final bool resaltado;
  const _TarjetaEspacio({super.key, required this.espacio, this.resaltado = false});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Card(
      shape: resaltado
          ? RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              side: BorderSide(color: esquema.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    espacio.nombre,
                    style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                _Etiqueta(etiquetaTipo(espacio.tipo)),
              ],
            ),
            if (espacio.salones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final salon in espacio.salones) _ChipSalon(salon.nombre)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de tipo: azul sobre tinte azul (7,1:1).
class _Etiqueta extends StatelessWidget {
  final String texto;
  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          texto,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: esquema.onPrimaryContainer),
        ),
      ),
    );
  }
}

/// Salón dentro de un espacio: texto navy sobre el fondo de la app (14:1).
class _ChipSalon extends StatelessWidget {
  final String nombre;
  const _ChipSalon(this.nombre);

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: esquema.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(nombre, style: TextStyle(fontSize: 13, color: esquema.onSurface)),
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
