import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/features/zonas/presentation/tipos_lugar.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';

/// Pruebas de cómo se muestran los tipos de lugar: etiquetas en español,
/// iniciales de zona y resumen.
void main() {
  group('etiquetaTipo', () {
    test('traduce los tipos conocidos', () {
      expect(etiquetaTipo('zona_comun'), 'Zona común');
      expect(etiquetaTipo('oficina_institucional'), 'Oficina institucional');
      expect(etiquetaTipo('salon'), 'Salón');
      expect(etiquetaTipo('cafeteria'), 'Cafetería');
      expect(etiquetaTipo('edificio'), 'Edificio');
    });

    test('un tipo nuevo se humaniza en lugar de mostrarse crudo', () {
      expect(etiquetaTipo('sala_de_estudio'), 'Sala de estudio');
      expect(etiquetaTipo('PUNTO__WIFI'), 'Punto wifi');
      expect(etiquetaTipo(''), 'Sin tipo');
    });

    group('con zonas.json', () {
      TestWidgetsFlutterBinding.ensureInitialized();

      test('cada tipo de zona y de espacio tiene una etiqueta de la tabla', () async {
        final zonas = await ZonaRepositoryLocal().obtenerPuntos();
        final tipos = {
          for (final zona in zonas) zona.tipo,
          for (final zona in zonas)
            for (final espacio in zona.espacios) espacio.tipo,
        };

        expect(tipos, isNotEmpty);
        for (final tipo in tipos) {
          final etiqueta = etiquetaTipo(tipo);
          expect(etiqueta, isNot(contains('_')), reason: tipo);
          expect(etiqueta[0], etiqueta[0].toUpperCase(), reason: tipo);
        }
        // Los que tienen tilde solo salen bien si están en la tabla.
        expect(tipos.map(etiquetaTipo), containsAll(['Zona común', 'Salón', 'Cafetería']));
      });
    });
  });

  group('inicialesZona', () {
    test('sigue los ejemplos de la propuesta de interfaz', () {
      expect(inicialesZona('A1'), 'A1');
      expect(inicialesZona('Zona T'), 'ZT');
      expect(inicialesZona('Biblioteca Luis Enrique Borja Barón'), 'BI');
      expect(inicialesZona('Alcatraz'), 'AL');
      expect(inicialesZona('Q'), 'Q');
      expect(inicialesZona('  '), '?');
    });
  });

  group('resumenZona', () {
    test('omite los pisos cuando no hay y usa singular cuando toca', () {
      final conPisos = Zona.fromJson({
        'id': 'a1',
        'nombre': 'A1',
        'tipo': 'edificio',
        'lat': 0,
        'lng': 0,
        'pisos': [
          {'id': 'p1', 'nombre': 'Piso 1'},
        ],
        'espacios': [
          {'id': 'e1', 'nombre': 'Aula', 'tipo': 'salon', 'pisos': ['p1']},
        ],
      });
      final sinPisos = Zona(id: 'zt', nombre: 'Zona T', tipo: 'zona_comun', lat: 0, lng: 0);

      expect(resumenZona(conPisos), 'Edificio · 1 piso · 1 espacio');
      expect(resumenZona(sinPisos), 'Zona común');
    });
  });

  group('estiloTipo', () {
    test('cada tipo de zona tiene su tinte; los desconocidos usan el de edificio', () {
      expect(estiloTipo('zona_comun'), estiloZonaComun);
      expect(estiloTipo('biblioteca'), estiloBiblioteca);
      expect(estiloTipo('servicio'), estiloServicio);
      expect(estiloTipo('algo_nuevo'), estiloEdificio);
    });
  });
}
