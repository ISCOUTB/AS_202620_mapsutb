import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/static_map_adapter.dart';
import 'package:mapsutb/core/app_colors.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import 'zona_detalle_screen.dart';

/// Color de acento de una tarjeta y su variante oscura (para textos).
class _Acento {
  final Color color;
  final Color oscuro;
  const _Acento(this.color, this.oscuro);
}

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

  // Colores que se van alternando entre tarjetas.
  static const _acentos = <_Acento>[
    _Acento(AppColors.azulPrincipal, AppColors.azulPrincipal),
    _Acento(AppColors.verdeEsmeralda, AppColors.verdeEsmeralda),
    _Acento(AppColors.celeste, AppColors.azulPrincipal),
    _Acento(AppColors.verdeLima, AppColors.verdeEsmeralda),
  ];

  @override
  void initState() {
    super.initState();
    _zonas = widget.repository.obtenerPuntos();
  }

  void _reintentar() {
    setState(() {
      _zonas = widget.repository.obtenerPuntos();
    });
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
        builder: (_) => ZonaDetalleScreen(
          zona: zona,
          staticMap: widget.staticMap,
          onComoLlegar: widget.onComoLlegar,
        ),
      ),
    );
  }

  /// Icono según el tipo de zona (si no coincide, un pin genérico).
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
    return FutureBuilder<List<Zona>>(
      future: _zonas,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off,
                      size: 56, color: AppColors.azulPrincipal.withOpacity(.6)),
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
                    onPressed: _reintentar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.azulPrincipal),
          );
        }

        final puntos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: puntos.length + 1, // +1 por el encabezado
          itemBuilder: (context, i) {
            if (i == 0) return _Encabezado(total: puntos.length);

            final punto = puntos[i - 1];
            final acento = _acentos[(i - 1) % _acentos.length];
            return _Aparece(
              indice: i - 1,
              child: _TarjetaZona(
                zona: punto,
                acento: acento,
                icono: _icono(punto.tipo),
                onTap: () => _abrirDetalle(punto),
              ),
            );
          },
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  final int total;
  const _Encabezado({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explora el campus',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
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
                '$total zonas disponibles',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaZona extends StatelessWidget {
  final Zona zona;
  final _Acento acento;
  final IconData icono;
  final VoidCallback onTap;

  const _TarjetaZona({
    required this.zona,
    required this.acento,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: acento.color.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Franja de color a la izquierda.
                Container(width: 8, color: acento.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Icono en cuadro con degradado.
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                acento.color,
                                acento.color.withOpacity(.65),
                              ],
                            ),
                          ),
                          child: Icon(icono, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zona.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B1B1F),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Etiqueta con el tipo.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: acento.color.withOpacity(.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  zona.tipo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: acento.oscuro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Flecha en círculo.
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: acento.color.withOpacity(.14),
                          ),
                          child: Icon(Icons.arrow_forward_ios_rounded,
                              size: 15, color: acento.oscuro),
                        ),
                      ],
                    ),
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

/// Animación de entrada: cada tarjeta sube y aparece con un pequeño retraso.
class _Aparece extends StatelessWidget {
  final int indice;
  final Widget child;
  const _Aparece({required this.indice, required this.child});

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