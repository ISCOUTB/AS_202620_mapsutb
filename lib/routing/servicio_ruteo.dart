import '../core/log.dart';
import 'grafo.dart';

/// Ruta a pie calculada sobre el grafo peatonal.
class Ruta {
  const Ruta({
    required this.nodos,
    required this.geometria,
    required this.metros,
    required this.tramosConEscaleras,
  });

  /// Velocidad de caminata usada para estimar el tiempo (1,2 m/s ≈ 4,3 km/h).
  static const velocidadMetrosPorSegundo = 1.2;

  /// Ids de los nodos recorridos, del origen al destino.
  final List<String> nodos;

  /// Puntos [lat, lng] para dibujar la ruta, del origen al destino.
  final List<List<double>> geometria;
  final double metros;
  final int tramosConEscaleras;

  Duration get tiempoCaminando =>
      Duration(seconds: (metros / velocidadMetrosPorSegundo).round());
}

/// Ruteo interno del campus con Dijkstra sobre el grafo propio (ADR 0013).
///
/// Solo conoce zonas por su id: el nodo de llegada de cada zona viene en
/// [GrafoPeatonal.entradas] (contexto Ruteo, ADR 0006).
class ServicioRuteo {
  ServicioRuteo(this._grafo);

  final GrafoPeatonal _grafo;

  /// Ruta entre dos zonas por sus ids, o null si alguna no tiene entrada o
  /// no hay camino entre ellas.
  Ruta? rutaEntreZonas(String zonaOrigen, String zonaDestino,
      {bool evitarEscaleras = false}) {
    final a = _grafo.entradas[zonaOrigen], b = _grafo.entradas[zonaDestino];
    if (a == null || b == null) return null;
    return rutaEntreNodos(a, b, evitarEscaleras: evitarEscaleras);
  }

  /// Ruta desde una posición (p. ej. la del GPS) hasta una zona: parte del
  /// nodo del grafo más cercano a esa posición.
  Ruta? rutaDesdePosicion(double lat, double lng, String zonaDestino,
      {bool evitarEscaleras = false}) {
    final b = _grafo.entradas[zonaDestino];
    final cercano = _grafo.nodoMasCercano(lat, lng);
    if (b == null || cercano == null) return null;
    return rutaEntreNodos(cercano.$1.id, b, evitarEscaleras: evitarEscaleras);
  }

  /// Dijkstra con montículo binario: camino de menor distancia en metros.
  Ruta? rutaEntreNodos(String origen, String destino,
      {bool evitarEscaleras = false}) {
    if (!_grafo.nodos.containsKey(origen) || !_grafo.nodos.containsKey(destino)) {
      return null;
    }
    final reloj = Stopwatch()..start();
    final distancia = <String, double>{origen: 0};
    final llegada = <String, TramoGrafo>{}; // tramo por el que se llegó a cada nodo
    final cerrados = <String>{};
    final cola = _Monticulo()..agregar(origen, 0);

    while (cola.isNotEmpty) {
      final (nodo, d) = cola.sacarMenor();
      if (!cerrados.add(nodo)) continue; // entrada vieja del montículo
      if (nodo == destino) break;
      for (final t in _grafo.tramosDe(nodo)) {
        if (evitarEscaleras && t.escaleras) continue;
        final vecino = t.otroExtremo(nodo);
        if (cerrados.contains(vecino)) continue;
        final nueva = d + t.metros;
        if (nueva < (distancia[vecino] ?? double.infinity)) {
          distancia[vecino] = nueva;
          llegada[vecino] = t;
          cola.agregar(vecino, nueva);
        }
      }
    }
    if (!cerrados.contains(destino)) {
      Log.warn('ruta_no_encontrada', {'origen': origen, 'destino': destino, 'evitar_escaleras': evitarEscaleras});
      return null;
    }

    // Reconstrucción: del destino hacia atrás por los tramos de llegada.
    final nodos = <String>[destino];
    final tramos = <TramoGrafo>[];
    var actual = destino;
    while (actual != origen) {
      final t = llegada[actual]!;
      tramos.add(t);
      actual = t.otroExtremo(actual);
      nodos.add(actual);
    }
    final enOrden = nodos.reversed.toList();
    final geometria = <List<double>>[];
    final tramosEnOrden = tramos.reversed.toList();
    for (var i = 0; i < tramosEnOrden.length; i++) {
      final puntos = tramosEnOrden[i].geometriaDesde(enOrden[i]);
      geometria.addAll(geometria.isEmpty ? puntos : puntos.skip(1));
    }
    if (geometria.isEmpty) {
      final n = _grafo.nodos[origen]!;
      geometria.add([n.lat, n.lng]);
    }
    final ruta = Ruta(
      nodos: enOrden,
      geometria: geometria,
      metros: distancia[destino]!,
      tramosConEscaleras: tramos.where((t) => t.escaleras).length,
    );
    Log.info('ruta_calculada', {
      'origen': origen,
      'destino': destino,
      'metros': ruta.metros.round(),
      'tramos': tramos.length,
      'duracion_us': reloj.elapsedMicroseconds,
    });
    return ruta;
  }
}

/// Montículo binario mínimo de (nodo, distancia). Se escribió aquí en lugar
/// de agregar package:collection como dependencia directa (ADR 0013).
class _Monticulo {
  final _nodos = <String>[];
  final _pesos = <double>[];

  bool get isNotEmpty => _nodos.isNotEmpty;

  void agregar(String nodo, double peso) {
    _nodos.add(nodo);
    _pesos.add(peso);
    var i = _nodos.length - 1;
    while (i > 0) {
      final padre = (i - 1) >> 1;
      if (_pesos[padre] <= _pesos[i]) break;
      _intercambiar(i, padre);
      i = padre;
    }
  }

  (String, double) sacarMenor() {
    final menor = (_nodos.first, _pesos.first);
    final ultimoNodo = _nodos.removeLast(), ultimoPeso = _pesos.removeLast();
    if (_nodos.isNotEmpty) {
      _nodos[0] = ultimoNodo;
      _pesos[0] = ultimoPeso;
      var i = 0;
      while (true) {
        final izq = 2 * i + 1, der = izq + 1;
        var menorHijo = i;
        if (izq < _nodos.length && _pesos[izq] < _pesos[menorHijo]) menorHijo = izq;
        if (der < _nodos.length && _pesos[der] < _pesos[menorHijo]) menorHijo = der;
        if (menorHijo == i) break;
        _intercambiar(i, menorHijo);
        i = menorHijo;
      }
    }
    return menor;
  }

  void _intercambiar(int a, int b) {
    final n = _nodos[a], p = _pesos[a];
    _nodos[a] = _nodos[b];
    _pesos[a] = _pesos[b];
    _nodos[b] = n;
    _pesos[b] = p;
  }
}
