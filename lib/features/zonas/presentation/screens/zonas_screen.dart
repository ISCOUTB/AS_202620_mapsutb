import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/features/busqueda/indice_busqueda.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import 'dart:ui';

import '../tipos_lugar.dart';
import '../widgets/resultados_busqueda.dart';
import 'zona_detalle_screen.dart';

/// Las dos grandes categorías en las que se agrupan las zonas.
enum _Categoria { estudio, recreacion }

class _InfoCategoria {
  final String titulo;
  final IconData icono;
  final String imagen;
  final Color color;

  const _InfoCategoria({
    required this.titulo,
    required this.icono,
    required this.imagen,
    required this.color,
  });
}

const _infoCategorias = <_Categoria, _InfoCategoria>{
  _Categoria.estudio: _InfoCategoria(
    titulo: 'Salones e instalaciones de estudio',
    icono: Icons.school_rounded,
    imagen: 'assets/categorias/estudio.jpg',
    color: AppColors.azulPrincipal,
  ),
  _Categoria.recreacion: _InfoCategoria(
    titulo: 'Recreación, interacción y zonas de descanso',
    icono: Icons.weekend_rounded,
    imagen: 'assets/categorias/recreacion.jpg',
    color: AppColors.morado,
  ),
};

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

class _ZonasScreenState extends State<ZonasScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Zona>> _zonas;

  // ---------- Animación de entrada ----------
  late final AnimationController _intro;
  late final Animation<double> _animEncabezado;
  late final Animation<double> _animBuscador;

  /// Categoría abierta; null = se ven las dos tarjetas de categoría.
  _Categoria? _categoria;

  /// Zonas de «Recreación, interacción y zonas de descanso» (por nombre,
  /// en minúsculas). Todas las demás van en «Salones e instalaciones de
  /// estudio». Agrega aquí cualquier zona nueva de recreación.
  static const _idsRecreacion = {'zonat', 'quid', 'espacioslibres'};

  // Colores de acento de las tarjetas de zona.
  static const _colores = <Color>[
    AppColors.azulPrincipal,
    AppColors.verdeEsmeralda,
    AppColors.celeste,
    AppColors.morado,
  ];

  // Índice de búsqueda y controlador del campo.
  IndiceBusqueda? _indice;
  final _consulta = TextEditingController();

  @override
  void initState() {
    super.initState();
    _zonas = _cargar();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animEncabezado = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _animBuscador = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
    );

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
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

  bool _esRecreacion(Zona z) =>
      _idsRecreacion.contains(z.id);

  List<Zona> _deCategoria(List<Zona> todas, _Categoria c) => todas
      .where((z) => _esRecreacion(z) == (c == _Categoria.recreacion))
      .toList();

  void _abrirDetalle(Zona zona, {String? pisoId, String? espacioId}) {
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

  /// Icono según el tipo de zona (se usa también como respaldo sin imagen).
  IconData _icono(String tipo) {
    final t = tipo.toLowerCase();

    if (t.contains('biblio')) return Icons.local_library;
    if (t.contains('cafe') || t.contains('comed') || t.contains('rest')) {
      return Icons.restaurant;
    }
    if (t.contains('lab')) return Icons.science;
    if (t.contains('deport') || t.contains('cancha') || t.contains('gim')) {
      return Icons.sports_soccer;
    }
    if (t.contains('admin')) return Icons.business_center;
    if (t.contains('aula') || t.contains('salon') || t.contains('edific')) {
      return Icons.school;
    }

    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Con una categoría abierta, «atrás» vuelve a las dos categorías.
      canPop: _categoria == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _categoria = null);
      },
      child: FutureBuilder<List<Zona>>(
        future: _zonas,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Encabezado
              _Entrada(
                animacion: _animEncabezado,
                child: _Encabezado(total: snapshot.data?.length),
              ),
              // 2. Buscador
              _Entrada(
                animacion: _animBuscador,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _CampoBusqueda(
                    controller: _consulta,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              // 3. Categorías / zonas
              Expanded(child: _cuerpo(snapshot)),
            ],
          );
        },
      ),
    );
  }

  Widget _cuerpo(AsyncSnapshot<List<Zona>> snapshot) {
    if (snapshot.hasError) {
      return _ErrorCarga(onReintentar: _reintentar);
    }
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.azulPrincipal),
      );
    }

    final puntos = snapshot.data!;
    final consulta = _consulta.text;
    // La barra inferior es flotante: deja espacio para que no tape nada.
    final margenInferior = MediaQuery.paddingOf(context).bottom + 16;

    // Búsqueda activa: resultados.
    if (consulta.trim().isNotEmpty) {
      return ResultadosBusqueda(
        consulta: consulta,
        resultados: _indice?.buscar(consulta) ?? const [],
        onAbrir: _abrirResultado,
        onComoLlegar: widget.onComoLlegar == null
            ? null
            : (r) => widget.onComoLlegar!(r.zona.id),
      );
    }

    final categoria = _categoria;

    // Paso 1: las dos categorías.
    if (categoria == null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, margenInferior),
        children: [
          for (final c in _Categoria.values)
            _Aparece(
              indice: c.index,
              child: _TarjetaImagen(
                imagen: _infoCategorias[c]!.imagen,
                color: _infoCategorias[c]!.color,
                icono: _infoCategorias[c]!.icono,
                titulo: _infoCategorias[c]!.titulo,
                subtitulo: _textoCantidad(_deCategoria(puntos, c).length),
                alto: 180,
                tamanoTitulo: 21,
                onTap: () => setState(() => _categoria = c),
              ),
            ),
        ],
      );
    }

    // Paso 2: zonas de la categoría elegida.
    final zonas = _deCategoria(puntos, categoria);
    final info = _infoCategorias[categoria]!;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, margenInferior),
      itemCount: zonas.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _BarraCategoria(
            titulo: info.titulo,
            color: info.color,
            onVolver: () => setState(() => _categoria = null),
          );
        }

        final zona = zonas[i - 1];
        return _Aparece(
          indice: i - 1,
          child: _TarjetaImagen(
            imagen: 'assets/zonas/${zona.id}.jpg',
            color: _colores[(i - 1) % _colores.length],
            icono: _icono(zona.tipo),
            titulo: zona.nombre,
            subtitulo: resumenZona(zona),
            alto: 190,
            tamanoTitulo: 20,
            onTap: () => _abrirDetalle(zona),
          ),
        );
      },
    );
  }

  static String _textoCantidad(int n) => '$n ${n == 1 ? 'lugar' : 'lugares'}';
}

// ---------------------------------------------------------------------------
// Encabezado y buscador
// ---------------------------------------------------------------------------

class _Encabezado extends StatelessWidget {
  final int? total;

  const _Encabezado({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explora el campus',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Montserrat',
              color: AppColors.azulPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.verdeLima,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total == null
                    ? 'Cargando instalaciones…'
                    : '$total instalaciones disponibles',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CampoBusqueda({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(30);

    return Container(
      // La sombra va afuera: el ClipRRect de abajo la recortaría.
      decoration: BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color: AppColors.azulOscuro.withAlpha(25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radio,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150), // vidrio esmerilado
              borderRadius: radio,
              border: Border.all(
                color: Colors.white.withAlpha(200),
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar lugar',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.azulPrincipal),
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
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de arriba cuando hay una categoría abierta: botón volver + título.
class _BarraCategoria extends StatelessWidget {
  final String titulo;
  final Color color;
  final VoidCallback onVolver;

  const _BarraCategoria({
    required this.titulo,
    required this.color,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onVolver,
            tooltip: 'Volver a categorías',
            icon: Icon(Icons.arrow_back_rounded, color: color),
          ),
          Expanded(
            child: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.azulOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta con imagen (sirve para categorías y para zonas)
// ---------------------------------------------------------------------------

class _TarjetaImagen extends StatelessWidget {
  final String imagen;
  final Color color;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final double alto;
  final double tamanoTitulo;
  final VoidCallback onTap;

  const _TarjetaImagen({
    required this.imagen,
    required this.color,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alto,
    required this.tamanoTitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);

    return Container(
      height: alto,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radio,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen (o degradado de respaldo si todavía no existe el archivo)
              Image.asset(
                imagen,
                fit: BoxFit.cover,
                cacheWidth: 900,
                errorBuilder: (_, __, ___) =>
                    _FondoRespaldo(color: color, icono: icono),
              ),
              // Degradado oscuro para que el texto se lea siempre
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.30, 1.0],
                    colors: [
                      Colors.transparent,
                      AppColors.azulOscuro.withAlpha(225),
                    ],
                  ),
                ),
              ),
              // Icono arriba a la izquierda
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(235),
                  ),
                  child: Icon(icono, color: Colors.white, size: 22),
                ),
              ),
              // Título y subtítulo abajo
              Positioned(
                left: 18,
                right: 68,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: tamanoTitulo,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Flecha abajo a la derecha
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(60),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondo que se muestra mientras una zona no tenga imagen.
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
              colors: [color, color.withAlpha(150)],
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: -10,
          child: Icon(icono, size: 130, color: Colors.white.withAlpha(40)),
        ),
      ],
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final VoidCallback onReintentar;

  const _ErrorCarga({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: AppColors.azulPrincipal.withAlpha(150),
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar las zonas.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.azulPrincipal,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azulPrincipal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animación de entrada de las tarjetas.
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

/// Fade + deslizamiento hacia arriba, controlado por una [Animation].
class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.animacion,
    required this.child,
  });

  final Animation<double> animacion;
  final Widget child;
  static const double _desplazamiento = 20;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacion,
      child: child,
      builder: (context, hijo) {
        final t = animacion.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _desplazamiento),
            child: hijo,
          ),
        );
      },
    );
  }
}