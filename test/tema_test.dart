import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/features/zonas/presentation/tema_maps_utb.dart';
import 'package:mapsutb/features/zonas/presentation/tipos_lugar.dart';
import 'package:mapsutb/main.dart';

/// Pruebas del tema global: usa la paleta del manual de identidad y cada
/// par de texto/fondo que usa la app llega al 4,5:1 de WCAG AA.

/// Relación de contraste WCAG 2.x entre dos colores opacos.
double _contraste(Color a, Color b) {
  final (claro, oscuro) = a.computeLuminance() > b.computeLuminance()
      ? (a.computeLuminance(), b.computeLuminance())
      : (b.computeLuminance(), a.computeLuminance());
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  final tema = temaMapsUtb();
  final esquema = tema.colorScheme;

  test('el esquema parte del azul Maps UTB y usa navy para el texto', () {
    expect(esquema.primary, ColoresMapsUtb.azul);
    expect(esquema.onSurface, ColoresMapsUtb.navy);
    expect(tema.scaffoldBackgroundColor, ColoresMapsUtb.fondo);
    expect(tema.appBarTheme.backgroundColor, ColoresMapsUtb.azul);
  });

  test('los colores coinciden con el manual de identidad visual', () {
    expect(ColoresMapsUtb.azul, const Color(0xFF093AD8));
    expect(ColoresMapsUtb.esmeralda, const Color(0xFF028C5C));
    expect(ColoresMapsUtb.lima, const Color(0xFF71EC37));
    expect(ColoresMapsUtb.navy, const Color(0xFF032742));
  });

  group('contraste de texto ≥ 4,5:1', () {
    final pares = <String, (Color, Color)>{
      'texto principal sobre tarjeta': (esquema.onSurface, esquema.surface),
      'texto principal sobre fondo': (esquema.onSurface, tema.scaffoldBackgroundColor),
      'texto secundario sobre tarjeta': (esquema.onSurfaceVariant, esquema.surface),
      'texto secundario sobre fondo': (esquema.onSurfaceVariant, tema.scaffoldBackgroundColor),
      'encabezado, botón y piso elegido': (esquema.onPrimary, esquema.primary),
      'etiqueta de tipo': (esquema.onPrimaryContainer, esquema.primaryContainer),
      'íconos y enlaces azules sobre tarjeta': (esquema.primary, esquema.surface),
      'iniciales de edificio': (estiloEdificio.texto, estiloEdificio.fondo),
      'iniciales de zona común': (estiloZonaComun.texto, estiloZonaComun.fondo),
      'iniciales de biblioteca': (estiloBiblioteca.texto, estiloBiblioteca.fondo),
      'iniciales de servicio': (estiloServicio.texto, estiloServicio.fondo),
    };
    for (final MapEntry(key: nombre, value: (texto, fondo)) in pares.entries) {
      test(nombre, () {
        expect(_contraste(texto, fondo), greaterThanOrEqualTo(4.5));
      });
    }
  });

  testWidgets('la app aplica el tema global', (tester) async {
    await tester.pumpWidget(const MapsUtbApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, ColoresMapsUtb.azul);
  });
}
