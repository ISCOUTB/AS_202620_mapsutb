import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/models/espacio.dart';
import 'package:mapsutb/models/imagen_mapa.dart';
import 'package:mapsutb/models/zona.dart';

import '../tipos_lugar.dart';

/// Colores que se alternan entre los pisos.
const _acentos = <Color>[
  AppColors.azulPrincipal,
  AppColors.verdeEsmeralda,
  AppColors.celeste,
  AppColors.verdeLima,
];

class ZonaDetalleScreen extends StatelessWidget {
  final Zona zona;
  final StaticMapAdapter? staticMap;

  final ValueChanged<String>? onComoLlegar;

  final String? pisoInicialId;
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
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(zona.nombre),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (staticMap != null && zona.tieneCoordenadas)
            _MiniaturaMapa(
              zona: zona,
              adapter: staticMap!,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              resumenZona(zona),
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onComoLlegar != null && zona.tieneCoordenadas)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilledButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: const Text('Cómo llegar'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onComoLlegar!(zona.id);
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

/// Selector de pisos y tarjetas de espacios.
///
/// Combina el selector mediante píldoras con las tarjetas
/// personalizadas de cada piso.
///
/// Los espacios que no pertenecen a ningún piso se muestran
/// en la sección "Otros espacios".
class _EspaciosPorPiso extends StatefulWidget {
  final Zona zona;
  final String? pisoInicialId;
  final String? espacioResaltadoId;

  const _EspaciosPorPiso({
    required this.zona,
    this.pisoInicialId,
    this.espacioResaltadoId,
  });

  @override
  State<_EspaciosPorPiso> createState() => _EspaciosPorPisoState();
}

class _EspaciosPorPisoState extends State<_EspaciosPorPiso> {
  static const _sinPiso = '';

  late String _seleccion;

  final GlobalKey _claveResaltado = GlobalKey();

  Zona get _zona => widget.zona;

  @override
  void initState() {
    super.initState();

    _seleccion = _seleccionInicial();

    _programarDesplazamiento();
  }

  @override
  void didUpdateWidget(covariant _EspaciosPorPiso oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.zona != widget.zona ||
        oldWidget.pisoInicialId != widget.pisoInicialId ||
        oldWidget.espacioResaltadoId != widget.espacioResaltadoId) {
      _seleccion = _seleccionInicial();
      _programarDesplazamiento();
    }
  }

  String _seleccionInicial() {
    final pisos = _zona.pisos;

    // Si se indicó un piso válido, se selecciona inicialmente.
    if (pisos.any((p) => p.id == widget.pisoInicialId)) {
      return widget.pisoInicialId!;
    }

    // Si el espacio buscado no tiene piso, se abre "Otros espacios".
    if (_zona.espaciosSinPiso.any(
      (e) => e.id == widget.espacioResaltadoId,
    )) {
      return _sinPiso;
    }

    // Si no hay piso inicial, se selecciona el primero.
    return pisos.isEmpty ? _sinPiso : pisos.first.id;
  }

  void _programarDesplazamiento() {
    if (widget.espacioResaltadoId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final contexto = _claveResaltado.currentContext;

      if (contexto != null && contexto.mounted) {
        Scrollable.ensureVisible(
          contexto,
          alignment: 0.1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _seleccionarPiso(String id) {
    setState(() {
      _seleccion = id;
    });

    _programarDesplazamiento();
  }

  @override
  Widget build(BuildContext context) {
    final pisos = _zona.pisos;
    final espaciosSinPiso = _zona.espaciosSinPiso;

    final bool hayOtrosEspacios = espaciosSinPiso.isNotEmpty;

    final bool mostrarSelector = pisos.isNotEmpty || hayOtrosEspacios;

    final espaciosSeleccionados = _seleccion == _sinPiso
        ? espaciosSinPiso
        : _zona.espaciosEnPiso(_seleccion);

    final indicePiso = pisos.indexWhere(
      (p) => p.id == _seleccion,
    );

    final color = indicePiso >= 0
        ? _acentos[indicePiso % _acentos.length]
        : AppColors.verdeEsmeralda;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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

        // Selector mediante píldoras.
        if (mostrarSelector)
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (int i = 0; i < pisos.length; i++)
                _PildoraPiso(
                  nombre: 'Piso ${i + 1}',
                  seleccionada: _seleccion == pisos[i].id,
                  color: _acentos[i % _acentos.length],
                  onTap: () => _seleccionarPiso(pisos[i].id),
                ),
              if (hayOtrosEspacios)
                _PildoraPiso(
                  nombre: 'Otros espacios',
                  seleccionada: _seleccion == _sinPiso,
                  color: AppColors.verdeEsmeralda,
                  onTap: () => _seleccionarPiso(_sinPiso),
                ),
            ],
          ),

        const SizedBox(height: 22),

        // Título dinámico de los espacios.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            _seleccion == _sinPiso
                ? 'Otros espacios'
                : 'Espacios del piso ${indicePiso + 1}',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.azulPrincipal,
            ),
          ),
        ),

        // Tarjetas de los espacios del piso seleccionado.
        if (espaciosSeleccionados.isEmpty)
          _MensajeVacio(
            icono: Icons.meeting_room_outlined,
            texto: _seleccion == _sinPiso
                ? 'No hay otros espacios registrados.'
                : 'Este piso no tiene espacios registrados.',
          )
        else
          for (final espacio in espaciosSeleccionados)
            _TarjetaEspacio(
              key: espacio.id == widget.espacioResaltadoId
                  ? _claveResaltado
                  : ValueKey(espacio.id),
              espacio: espacio,
              resaltado: espacio.id == widget.espacioResaltadoId,
              color: color,
            ),

        // Si no existen pisos ni espacios, se muestra un mensaje.
        if (!mostrarSelector)
          const _MensajeVacio(
            icono: Icons.layers_clear_outlined,
            texto: 'Esta zona no tiene pisos ni espacios registrados.',
          ),
      ],
    );
  }
}

/// Píldora para seleccionar un piso u otros espacios.
class _PildoraPiso extends StatelessWidget {
  final String nombre;
  final bool seleccionada;
  final Color color;
  final VoidCallback onTap;

  const _PildoraPiso({
    required this.nombre,
    required this.seleccionada,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(nombre),
      selected: seleccionada,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: color,
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: seleccionada
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color:
            seleccionada ? color : Theme.of(context).colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

/// Tarjeta personalizada de un espacio.
class _TarjetaEspacio extends StatelessWidget {
  final Espacio espacio;
  final bool resaltado;
  final Color color;

  const _TarjetaEspacio({
    super.key,
    required this.espacio,
    this.resaltado = false,
    this.color = AppColors.azulPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: resaltado
            ? Border.all(
                color: color,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    espacio.nombre,
                    style: textos.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.azulPrincipal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Etiqueta(etiquetaTipo(espacio.tipo)),
              ],
            ),
            if (espacio.salones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final salon in espacio.salones) _ChipSalon(salon.nombre),
                ],
              ),
            ],
            if (resaltado) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Espacio seleccionado',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Etiqueta del tipo de espacio.
class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: esquema.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Chip de salón.
class _ChipSalon extends StatelessWidget {
  final String nombre;

  const _ChipSalon(this.nombre);

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: esquema.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Text(
          nombre,
          style: TextStyle(
            fontSize: 13,
            color: esquema.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Mensaje para listas vacías.
class _MensajeVacio extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _MensajeVacio({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            icono,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura estática del mapa de la zona.
class _MiniaturaMapa extends StatefulWidget {
  final Zona zona;
  final StaticMapAdapter adapter;

  const _MiniaturaMapa({
    required this.zona,
    required this.adapter,
  });

  @override
  State<_MiniaturaMapa> createState() => _MiniaturaMapaState();
}

class _MiniaturaMapaState extends State<_MiniaturaMapa> {
  late Future<ImagenMapa> _imagen;

  @override
  void initState() {
    super.initState();
    _cargarImagen();
  }

  void _cargarImagen() {
    _imagen = widget.adapter.obtenerImagenMapa(
      lat: widget.zona.lat,
      lng: widget.zona.lng,
    );
  }

  @override
  void didUpdateWidget(covariant _MiniaturaMapa oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.zona != widget.zona || oldWidget.adapter != widget.adapter) {
      _cargarImagen();
    }
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
                  Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: Colors.grey.shade500,
                  ),
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
