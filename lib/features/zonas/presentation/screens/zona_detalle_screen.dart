import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/models/espacio.dart';
import 'package:mapsutb/models/imagen_mapa.dart';
import 'package:mapsutb/models/salon.dart';
import 'package:mapsutb/models/zona.dart';

import '../tipos_lugar.dart';

/// Colores que se alternan entre los pisos.
const _acentos = <Color>[
  AppColors.azulPrincipal,
  AppColors.verdeEsmeralda,
  AppColors.celeste,
  AppColors.verdeLima,
];

const _fuente = 'Montserrat';

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

/// Texto legible sobre un fondo de color (el verde lima, por ejemplo,
/// no admite texto blanco).
Color _textoSobre(Color fondo) =>
    ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
        ? Colors.white
        : AppColors.azulOscuro;

/// Versión oscurecida del acento, legible sobre fondos claros.
Color _acentoOscuro(Color color) =>
    Color.lerp(color, AppColors.azulOscuro, .5)!;

IconData _iconoZona(String tipo) {
  final t = tipo.toLowerCase();
  if (t.contains('biblio')) return Icons.local_library_rounded;
  if (t.contains('edific')) return Icons.apartment_rounded;
  if (t.contains('cafe') || t.contains('comed') || t.contains('rest')) {
    return Icons.restaurant_rounded;
  }
  if (t.contains('zona')) return Icons.weekend_rounded;
  if (t.contains('serv')) return Icons.room_service_rounded;
  return Icons.place_rounded;
}

IconData _iconoEspacio(String tipo) {
  final t = tipo.toLowerCase();
  if (t.contains('lab')) return Icons.science_rounded;
  if (t.contains('ofic')) return Icons.business_center_rounded;
  if (t.contains('cafe')) return Icons.local_cafe_rounded;
  if (t.contains('audit')) return Icons.theater_comedy_rounded;
  if (t.contains('salon') || t.contains('aula')) {
    return Icons.meeting_room_rounded;
  }
  if (t.contains('serv')) return Icons.room_service_rounded;
  return Icons.place_rounded;
}

// ---------------------------------------------------------------------------
// Pantalla
// ---------------------------------------------------------------------------

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
    final conMapa = staticMap != null && zona.tieneCoordenadas;
    final conRuta = onComoLlegar != null && zona.tieneCoordenadas;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CabeceraZona(zona: zona),
          if (conMapa)
            SliverToBoxAdapter(
              child: _Aparece(
                indice: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _MiniaturaMapa(zona: zona, adapter: staticMap!),
                ),
              ),
            ),
          if (conRuta)
            SliverToBoxAdapter(
              child: _Aparece(
                indice: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.azulPrincipal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: _fuente,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: const Text('Cómo llegar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onComoLlegar!(zona.id);
                    },
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
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

// ---------------------------------------------------------------------------
// Cabecera con degradado (se contrae al hacer scroll)
// ---------------------------------------------------------------------------

class _CabeceraZona extends StatelessWidget {
  final Zona zona;

  const _CabeceraZona({required this.zona});

  static const _altoExpandido = 230.0;

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    final minimo = arriba + kToolbarHeight;
    final maximo = arriba + _altoExpandido;

    return SliverAppBar(
      pinned: true,
      expandedHeight: _altoExpandido,
      backgroundColor: AppColors.azulOscuro,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, c) {
          // 1 = totalmente expandida, 0 = contraída.
          final t = ((c.maxHeight - minimo) / (maximo - minimo)).clamp(0.0, 1.0);
          final expandido = ((t - 0.35) / 0.55).clamp(0.0, 1.0);
          final colapsado = ((0.4 - t) / 0.3).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.azulPrincipal, AppColors.azulOscuro],
                  ),
                ),
              ),
              // Ícono decorativo grande.
              Positioned(
                right: -12,
                top: arriba + 8,
                child: Opacity(
                  opacity: t,
                  child: Icon(
                    _iconoZona(zona.tipo),
                    size: 150,
                    color: Colors.white.withAlpha(36),
                  ),
                ),
              ),
              // Información (visible cuando está expandida).
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Opacity(
                  opacity: expandido,
                  child: Transform.translate(
                    offset: Offset(0, (1 - expandido) * 12),
                    child: _Aparece(
                      indice: 0,
                      child: _InfoCabecera(zona: zona),
                    ),
                  ),
                ),
              ),
              // Título (visible cuando está contraída).
              Positioned(
                left: 56,
                right: 16,
                bottom: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: colapsado,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      zona.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _fuente,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCabecera extends StatelessWidget {
  final Zona zona;

  const _InfoCabecera({required this.zona});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(45),
          ),
          child: Icon(_iconoZona(zona.tipo), color: Colors.white, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          zona.nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: _fuente,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            height: 1.1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.verdeLima,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                resumenZona(zona),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _fuente,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Selector de pisos y tarjetas de espacios
// ---------------------------------------------------------------------------

/// Selector de pisos (píldoras animadas) y tarjetas de espacios.
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
    if (id == _seleccion) return;

    setState(() {
      _seleccion = id;
    });

    _programarDesplazamiento();
  }

  @override
  Widget build(BuildContext context) {
    final pisos = _zona.pisos;
    final espaciosSinPiso = _zona.espaciosSinPiso;

    final hayPisos = pisos.isNotEmpty;
    final hayOtrosEspacios = espaciosSinPiso.isNotEmpty;
    final hayContenido = hayPisos || hayOtrosEspacios;

    final espaciosSeleccionados = _seleccion == _sinPiso
        ? espaciosSinPiso
        : _zona.espaciosEnPiso(_seleccion);

    final indicePiso = pisos.indexWhere((p) => p.id == _seleccion);

    final color = indicePiso >= 0
        ? _acentos[indicePiso % _acentos.length]
        : AppColors.verdeEsmeralda;

    final tituloLista = indicePiso >= 0
        ? pisos[indicePiso].nombre
        : (hayPisos ? 'Otros espacios' : 'Todos los espacios');

    final n = espaciosSeleccionados.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        24,
        0,
        MediaQuery.paddingOf(context).bottom + 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección.
          _Aparece(
            indice: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TituloSeccion(hayPisos ? 'Pisos' : 'Espacios'),
            ),
          ),

          // Selector mediante píldoras (con scroll horizontal).
          if (hayPisos) ...[
            const SizedBox(height: 10),
            _Aparece(
              indice: 3,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < pisos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _PildoraPiso(
                          nombre: pisos[i].nombre,
                          seleccionada: _seleccion == pisos[i].id,
                          color: _acentos[i % _acentos.length],
                          onTap: () => _seleccionarPiso(pisos[i].id),
                        ),
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
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Lista del piso seleccionado. La clave hace que, al cambiar de
          // piso, las tarjetas vuelvan a entrar con su animación.
          if (hayContenido)
            KeyedSubtree(
              key: ValueKey(_seleccion),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        bottom: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tituloLista,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: _fuente,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                '$n ${n == 1 ? 'espacio' : 'espacios'}',
                                style: const TextStyle(
                                  fontFamily: _fuente,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.azulOscuro,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (espaciosSeleccionados.isEmpty)
                      _MensajeVacio(
                        icono: Icons.meeting_room_outlined,
                        texto: _seleccion == _sinPiso
                            ? 'No hay otros espacios registrados.'
                            : 'Este piso no tiene espacios registrados.',
                      )
                    else
                      for (var i = 0; i < espaciosSeleccionados.length; i++)
                        _Aparece(
                          indice: i,
                          child: _TarjetaEspacio(
                            key: espaciosSeleccionados[i].id ==
                                    widget.espacioResaltadoId
                                ? _claveResaltado
                                : ValueKey(espaciosSeleccionados[i].id),
                            zona: _zona,
                            espacio: espaciosSeleccionados[i],
                            resaltado: espaciosSeleccionados[i].id ==
                                widget.espacioResaltadoId,
                            color: color,
                          ),
                        ),
                  ],
                ),
              ),
            ),

          // Si no existen pisos ni espacios, se muestra un mensaje.
          if (!hayContenido)
            const _MensajeVacio(
              icono: Icons.layers_clear_outlined,
              texto: 'Esta zona no tiene pisos ni espacios registrados.',
            ),
        ],
      ),
    );
  }
}

/// Título de sección con la barrita lima.
class _TituloSeccion extends StatelessWidget {
  final String texto;
  final double tamano;

  const _TituloSeccion(this.texto, {this.tamano = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          texto,
          style: TextStyle(
            fontFamily: _fuente,
            fontSize: tamano,
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
    );
  }
}

/// Píldora animada para seleccionar un piso u otros espacios.
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
    final radio = BorderRadius.circular(14);

    return AnimatedScale(
      scale: seleccionada ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: seleccionada ? color : Colors.white,
          borderRadius: radio,
          border: Border.all(
            color: seleccionada ? color : color.withAlpha(110),
            width: 1.4,
          ),
          boxShadow: seleccionada
              ? [
                  BoxShadow(
                    color: color.withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radio,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontFamily: _fuente,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: seleccionada ? _textoSobre(color) : AppColors.azulOscuro,
                ),
                child: Text(nombre),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de espacio y chips de salón
// ---------------------------------------------------------------------------

/// Tarjeta personalizada de un espacio.
class _TarjetaEspacio extends StatelessWidget {
  final Zona zona;
  final Espacio espacio;
  final bool resaltado;
  final Color color;

  const _TarjetaEspacio({
    super.key,
    required this.zona,
    required this.espacio,
    this.resaltado = false,
    this.color = AppColors.azulPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(20);
    final colorTexto = _acentoOscuro(color);
    final n = espacio.salones.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radio,
        border: resaltado ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(resaltado ? 90 : 45),
            blurRadius: resaltado ? 20 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radio,
        child: Stack(
          children: [
            // Franja de color a la izquierda.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withAlpha(36),
                        ),
                        child: Icon(
                          _iconoEspacio(espacio.tipo),
                          size: 21,
                          color: colorTexto,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              espacio.nombre,
                              style: const TextStyle(
                                fontFamily: _fuente,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                height: 1.2,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            if (n > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                '$n ${n == 1 ? 'salón' : 'salones'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Etiqueta(etiquetaTipo(espacio.tipo), color: color),
                    ],
                  ),
                  if (espacio.salones.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final salon in espacio.salones)
                          _ChipSalon(
                            nombre: salon.nombre,
                            color: color,
                            onTap: () => _mostrarHojaSalon(
                              context,
                              zona: zona,
                              espacio: espacio,
                              salon: salon,
                              color: color,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (resaltado) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: colorTexto, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Espacio seleccionado',
                          style: TextStyle(
                            color: colorTexto,
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
          ],
        ),
      ),
    );
  }
}

/// Etiqueta del tipo de espacio.
class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;

  const _Etiqueta(this.texto, {required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          texto,
          style: TextStyle(
            fontFamily: _fuente,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _acentoOscuro(color),
          ),
        ),
      ),
    );
  }
}

/// Chip de salón: al tocarlo abre la hoja con imagen y descripción.
class _ChipSalon extends StatelessWidget {
  final String nombre;
  final Color color;
  final VoidCallback onTap;

  const _ChipSalon({
    required this.nombre,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texto = _acentoOscuro(color);

    return Material(
      color: color.withAlpha(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(100)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  nombre,
                  style: TextStyle(
                    fontFamily: _fuente,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: texto,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: texto),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hoja de detalle de un salón (imagen + descripción)
// ---------------------------------------------------------------------------

void _mostrarHojaSalon(
  BuildContext context, {
  required Zona zona,
  required Espacio espacio,
  required Salon salon,
  required Color color,
}) {
  final pisos = zona.pisos
      .where((p) => espacio.pisos.contains(p.id))
      .map((p) => p.nombre)
      .join(' · ');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HojaSalon(
      salon: salon,
      espacio: espacio,
      pisos: pisos,
      color: color,
    ),
  );
}

class _HojaSalon extends StatelessWidget {
  final Salon salon;
  final Espacio espacio;
  final String pisos;
  final Color color;

  const _HojaSalon({
    required this.salon,
    required this.espacio,
    required this.pisos,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final descripcion = salon.descripcion?.trim();
    final tieneDescripcion = descripcion != null && descripcion.isNotEmpty;
    final icono = _iconoEspacio(espacio.tipo);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Asa de arrastre.
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Aparece(
                    indice: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _ImagenSalon(
                          ruta: salon.rutaImagen,
                          color: color,
                          icono: icono,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Aparece(
                    indice: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.nombre,
                          style: const TextStyle(
                            fontFamily: _fuente,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DatoUbicacion(
                              icono: icono,
                              texto: espacio.nombre,
                              color: color,
                            ),
                            if (pisos.isNotEmpty)
                              _DatoUbicacion(
                                icono: Icons.layers_rounded,
                                texto: pisos,
                                color: color,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Aparece(
                    indice: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TituloSeccion('Descripción', tamano: 17),
                        const SizedBox(height: 10),
                        if (tieneDescripcion)
                          Text(
                            descripcion,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.5,
                              color: Colors.grey.shade800,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Aún no hay descripción para este salón.',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dato de ubicación (espacio / piso) dentro de la hoja del salón.
class _DatoUbicacion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _DatoUbicacion({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 15, color: _acentoOscuro(color)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: const TextStyle(
                  fontFamily: _fuente,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulOscuro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Imagen del salón (asset o URL). Mientras no exista, o si falla,
/// se ve el degradado de respaldo; cuando carga, aparece con fundido.
class _ImagenSalon extends StatelessWidget {
  final String ruta;
  final Color color;
  final IconData icono;

  const _ImagenSalon({
    required this.ruta,
    required this.color,
    required this.icono,
  });

  static Widget _fundido(
    BuildContext context,
    Widget child,
    int? frame,
    bool sincrona,
  ) =>
      AnimatedOpacity(
        opacity: sincrona || frame != null ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: child,
      );

  static Widget _sinImagen(
    BuildContext context,
    Object error,
    StackTrace? stack,
  ) =>
      const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final esRed = ruta.startsWith('http');

    return Stack(
      fit: StackFit.expand,
      children: [
        _FondoRespaldo(color: color, icono: icono),
        esRed
            ? Image.network(
                ruta,
                fit: BoxFit.cover,
                frameBuilder: _fundido,
                errorBuilder: _sinImagen,
              )
            : Image.asset(
                ruta,
                fit: BoxFit.cover,
                frameBuilder: _fundido,
                errorBuilder: _sinImagen,
              ),
      ],
    );
  }
}

/// Fondo que se muestra mientras un salón no tenga imagen.
class _FondoRespaldo extends StatelessWidget {
  final Color color;
  final IconData icono;

  const _FondoRespaldo({required this.color, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, AppColors.azulOscuro],
            ),
          ),
        ),
        Positioned(
          right: -10,
          bottom: -14,
          child: Icon(icono, size: 140, color: Colors.white.withAlpha(40)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Utilidades de UI
// ---------------------------------------------------------------------------

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
      child: Center(
        child: Column(
          children: [
            Icon(icono, size: 42, color: Colors.grey.shade500),
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
      ),
    );
  }
}

/// Animación de entrada: fade + deslizamiento hacia arriba, escalonada.
class _Aparece extends StatelessWidget {
  final int indice;
  final Widget child;

  const _Aparece({
    required this.indice,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final extra = (indice < 8 ? indice : 8) * 70;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + extra),
      curve: Curves.easeOutCubic,
      builder: (context, v, hijo) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - v)),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Miniatura del mapa
// ---------------------------------------------------------------------------

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
    final zona = widget.zona;
    final lat = zona.lat;
    final lng = zona.lng;

    // Sin coordenadas reales (null o el relleno 0,0) no hay mapa que pedir.
    // El FutureBuilder ya muestra "Mapa no disponible." cuando hay error.
    if (lat == null || lng == null || !zona.tieneCoordenadas) {
      _imagen = Future.error('La zona ${zona.id} no tiene coordenadas');
      return;
    }

    _imagen = widget.adapter.obtenerImagenMapa(lat: lat, lng: lng);
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
    final radio = BorderRadius.circular(22);

    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color: AppColors.azulOscuro.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radio,
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
              width: double.infinity,
            );
          },
        ),
      ),
    );
  }
}