import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/features/busqueda/indice_busqueda.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';

/// Pruebas del índice del buscador de zonas, espacios y salones: reglas de
/// normalización, coincidencia y orden con datos pequeños, y los ejemplos
/// de uso real contra assets/data/zonas.json.

Zona _zona(String id, String nombre, {List<Map<String, dynamic>> pisos = const [], List<Map<String, dynamic>> espacios = const []}) =>
    Zona.fromJson({'id': id, 'nombre': nombre, 'tipo': 'edificio', 'lat': 0, 'lng': 0, 'pisos': pisos, 'espacios': espacios});

void main() {
  group('normalizarBusqueda', () {
    test('quita mayúsculas, tildes, signos y espacios repetidos', () {
      expect(normalizarBusqueda('  Enfermería '), 'enfermeria');
      expect(normalizarBusqueda('ÁRBOL   Ñandú'), 'arbol nandu');
      expect(normalizarBusqueda('406 - Lab de Redes'), '406 lab de redes');
      expect(normalizarBusqueda('Laboratorio de Simulación E&E'), 'laboratorio de simulacion e e');
    });

    test('también quita tildes escritas como carácter combinante (NFD)', () {
      expect(normalizarBusqueda('Enfermería'), 'enfermeria');
    });
  });

  group('IndiceBusqueda', () {
    final zonas = [
      _zona('a1', 'A1', pisos: [
        {'id': 'a1-p4', 'nombre': 'Cuarto Piso'},
      ], espacios: [
        {
          'id': 'a1-sis',
          'nombre': 'Salón de Sistemas / Laboratorios de Computadores',
          'tipo': 'laboratorio',
          'pisos': ['a1-p4'],
          'salones': [
            {'id': 'a1-401', 'nombre': '401'},
            {'id': 'a1-406', 'nombre': '406 - Lab de Redes'},
          ],
        },
      ]),
      _zona('a2', 'A2', pisos: [
        {'id': 'a2-p4', 'nombre': 'Cuarto Piso'},
      ], espacios: [
        {
          'id': 'a2-s4',
          'nombre': 'Salones 401-408',
          'tipo': 'salon',
          'pisos': ['a2-p4'],
          'salones': [
            {'id': 'a2-401', 'nombre': '401'},
          ],
        },
      ]),
      _zona('zonat', 'Zona T', espacios: [
        {'id': 'zt-enf', 'nombre': 'Enfermería', 'tipo': 'servicio', 'pisos': []},
      ]),
    ];
    final indice = IndiceBusqueda(zonas);

    List<String> titulos(String consulta) => indice.buscar(consulta).map((r) => r.titulo).toList();

    test('indexa zonas, espacios y salones', () {
      expect(indice.cantidad, 3 + 3 + 3);
    });

    test('una consulta vacía o solo con espacios no devuelve nada', () {
      expect(indice.buscar(''), isEmpty);
      expect(indice.buscar('   '), isEmpty);
    });

    test('todas las palabras deben coincidir, en cualquier orden', () {
      expect(titulos('lab sistemas'), ['Salón de Sistemas / Laboratorios de Computadores', '406 - Lab de Redes']);
      expect(titulos('sistemas lab'), titulos('lab sistemas'));
      expect(titulos('lab piscina'), isEmpty);
    });

    test('una zona no arrastra todos sus espacios y salones', () {
      expect(titulos('a2'), ['A2']);
    });

    test('el contexto ayuda a desambiguar: "a2 401" es el salón del A2', () {
      final resultados = indice.buscar('a2 401');
      expect(resultados.map((r) => r.titulo), ['Salones 401-408', 'Salón 401']);
      expect(resultados.last.zona.id, 'a2');
    });

    test('exacto antes que prefijo antes que el resto; zona antes que espacio y salón', () {
      // "401" es exacto para los dos salones 401; en "Salones 401-408" solo
      // está contenido, así que ese espacio va después aunque sea espacio.
      final resultados = indice.buscar('401');
      expect(resultados.map((r) => '${r.tipo.name}:${r.zona.id}:${r.titulo}'), [
        'salon:a1:Salón 401',
        'salon:a2:Salón 401',
        'espacio:a2:Salones 401-408',
      ]);
    });

    test('un salón dice en qué zona, piso y espacio está', () {
      final salon = indice.buscar('406').single;
      expect(salon.tipo, TipoResultado.salon);
      expect(salon.donde, 'A1 · Cuarto Piso');
      expect(salon.espacio!.id, 'a1-sis');
      expect(salon.piso!.id, 'a1-p4');
    });

    test('un espacio sin piso dice solo la zona', () {
      final enfermeria = indice.buscar('ENFERMERÍA').single;
      expect(enfermeria.tipo, TipoResultado.espacio);
      expect(enfermeria.piso, isNull);
      expect(enfermeria.donde, 'Zona T');
    });
  });

  group('IndiceBusqueda con zonas.json', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late IndiceBusqueda indice;

    setUpAll(() async {
      indice = IndiceBusqueda(await ZonaRepositoryLocal().obtenerPuntos());
    });

    test('"biblioteca" pone primero la zona Biblioteca', () {
      final resultados = indice.buscar('biblioteca');
      expect(resultados.first.tipo, TipoResultado.zona);
      expect(resultados.first.zona.id, 'biblioteca');
    });

    test('"lab sistemas" encuentra los laboratorios de computadores del A1', () {
      final primero = indice.buscar('lab sistemas').first;
      expect(primero.titulo, 'Salón de Sistemas / Laboratorios de Computadores');
      expect(primero.donde, 'A1 · Cuarto Piso');
    });

    test('"a2" devuelve el edificio A2 primero', () {
      final primero = indice.buscar('a2').first;
      expect(primero.tipo, TipoResultado.zona);
      expect(primero.zona.id, 'a2');
    });

    test('"enfermeria" encuentra la enfermería de Zona T, que no tiene pisos', () {
      final enfermeria = indice.buscar('enfermeria').single;
      expect(enfermeria.titulo, 'Enfermería');
      expect(enfermeria.donde, 'Zona T');
    });

    test('cada resultado es un punto distinto (no hay duplicados)', () {
      final ids = indice.buscar('salon').map((r) => '${r.zona.id}/${r.espacio?.id}/${r.salon?.id}');
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
