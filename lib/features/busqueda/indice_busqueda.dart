import 'package:mapsutb/models/espacio.dart';
import 'package:mapsutb/models/piso.dart';
import 'package:mapsutb/models/salon.dart';
import 'package:mapsutb/models/zona.dart';

/// Qué encontró el buscador. El orden es el de prioridad en los resultados:
/// a igual coincidencia, una zona va antes que un espacio y este antes que
/// un salón.
enum TipoResultado { zona, espacio, salon }

/// Un punto de interés encontrado: la zona siempre está (es a donde lleva
/// "Cómo llegar"); espacio, salón y piso solo cuando aplican.
class ResultadoBusqueda {
  final TipoResultado tipo;
  final Zona zona;
  final Espacio? espacio;
  final Salon? salon;

  /// Piso donde está el espacio (el primero, si abarca varios). Null en
  /// zonas sin pisos registrados.
  final Piso? piso;

  const ResultadoBusqueda._(this.tipo, this.zona, {this.espacio, this.salon, this.piso});

  /// Nombre que se muestra. Los salones con código numérico ("401",
  /// "104B") se muestran como "Salón 401" para que se entiendan solos.
  String get titulo => switch (tipo) {
        TipoResultado.zona => zona.nombre,
        TipoResultado.espacio => espacio!.nombre,
        TipoResultado.salon => _esCodigo.hasMatch(salon!.nombre) ? 'Salón ${salon!.nombre}' : salon!.nombre,
      };

  /// Dónde queda: "A1 · Cuarto Piso", o solo "Zona T" si no hay piso.
  String get donde => piso == null ? zona.nombre : '${zona.nombre} · ${piso!.nombre}';

  static final _esCodigo = RegExp(r'^\d{3}[A-Za-z]?$');
}

/// Índice en memoria de zonas, espacios y salones para buscar por nombre o
/// código. Se arma una sola vez con las zonas ya cargadas (no consulta
/// ningún Repository) y cada búsqueda recorre unas pocas centenas de
/// entradas, así que no necesita estructuras más elaboradas.
///
/// Reglas:
/// - Sin distinguir mayúsculas ni tildes, y con espacios colapsados.
/// - Todas las palabras de la consulta deben aparecer (como subcadena) en
///   el nombre del resultado o en su contexto (zona, piso, espacio), y al
///   menos una en el propio nombre: "a2 401" encuentra el salón 401 del A2,
///   pero "a2" no devuelve cada salón del A2, solo la zona.
/// - Orden: coincidencia exacta, luego prefijo, luego el resto; a igual
///   coincidencia, zonas antes que espacios y estos antes que salones.
class IndiceBusqueda {
  IndiceBusqueda(List<Zona> zonas) {
    for (final zona in zonas) {
      _agregar(
        ResultadoBusqueda._(TipoResultado.zona, zona),
        nombres: [zona.nombre, zona.id],
        contexto: const [],
      );
      final pisos = {for (final p in zona.pisos) p.id: p};
      for (final espacio in zona.espacios) {
        final piso = espacio.pisos.map((id) => pisos[id]).whereType<Piso>().firstOrNull;
        final contexto = [zona.nombre, zona.id, if (piso != null) piso.nombre];
        final resultadoEspacio = ResultadoBusqueda._(TipoResultado.espacio, zona, espacio: espacio, piso: piso);
        _agregar(resultadoEspacio, nombres: [espacio.nombre], contexto: contexto);
        for (final salon in espacio.salones) {
          final resultado =
              ResultadoBusqueda._(TipoResultado.salon, zona, espacio: espacio, salon: salon, piso: piso);
          _agregar(
            resultado,
            nombres: [resultado.titulo, salon.nombre],
            contexto: [...contexto, espacio.nombre],
          );
        }
      }
    }
  }

  final _entradas = <_Entrada>[];

  /// Cantidad de puntos indexados (zonas + espacios + salones).
  int get cantidad => _entradas.length;

  void _agregar(ResultadoBusqueda resultado, {required List<String> nombres, required List<String> contexto}) {
    final propios = nombres.map(normalizarBusqueda).toList();
    _entradas.add(_Entrada(
      resultado,
      propios: propios,
      todo: [...propios, ...contexto.map(normalizarBusqueda)].join(' '),
      orden: _entradas.length,
    ));
  }

  List<ResultadoBusqueda> buscar(String consulta) {
    final q = normalizarBusqueda(consulta);
    if (q.isEmpty) return const [];
    final palabras = q.split(' ');

    final encontrados = <(int, _Entrada)>[];
    for (final entrada in _entradas) {
      if (!palabras.every(entrada.todo.contains)) continue;
      if (!palabras.any((p) => entrada.propios.any((n) => n.contains(p)))) continue;
      final rango = entrada.propios.any((n) => n == q)
          ? 0
          : entrada.propios.any((n) => n.startsWith(q))
              ? 1
              : 2;
      encontrados.add((rango, entrada));
    }
    encontrados.sort((a, b) {
      final porRango = a.$1.compareTo(b.$1);
      if (porRango != 0) return porRango;
      final porTipo = a.$2.resultado.tipo.index.compareTo(b.$2.resultado.tipo.index);
      if (porTipo != 0) return porTipo;
      return a.$2.orden.compareTo(b.$2.orden);
    });
    return [for (final (_, entrada) in encontrados) entrada.resultado];
  }
}

class _Entrada {
  final ResultadoBusqueda resultado;

  /// Nombres propios normalizados (nombre, código o id).
  final List<String> propios;

  /// Nombres propios más el contexto, normalizados y unidos.
  final String todo;

  /// Posición en zonas.json, para que el orden sea estable.
  final int orden;

  _Entrada(this.resultado, {required this.propios, required this.todo, required this.orden});
}

const _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// Minúsculas, sin tildes, signos como espacio y espacios colapsados:
/// "  Enfermería " → "enfermeria", "406 - Lab de Redes" → "406 lab de redes".
String normalizarBusqueda(String texto) {
  final buffer = StringBuffer();
  for (final caracter in texto.toLowerCase().split('')) {
    buffer.write(_sinTilde[caracter] ?? caracter);
  }
  return buffer
      .toString()
      // Tildes escritas como carácter combinante (texto en forma NFD).
      .replaceAll(RegExp('[̀-ͯ]'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
