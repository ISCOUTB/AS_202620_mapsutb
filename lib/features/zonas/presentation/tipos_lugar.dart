import 'package:flutter/material.dart';
import 'package:mapsutb/models/zona.dart';

import 'tema_maps_utb.dart';

/// Etiquetas en español para los valores de `tipo` de zonas.json (zonas y
/// espacios). Es el único lugar donde se traduce un tipo para mostrarlo.
const _etiquetas = {
  'auditorio': 'Auditorio',
  'biblioteca': 'Biblioteca',
  'cafeteria': 'Cafetería',
  'edificio': 'Edificio',
  'laboratorio': 'Laboratorio',
  'oficina': 'Oficina',
  'oficina_institucional': 'Oficina institucional',
  'parqueadero': 'Parqueadero',
  'salon': 'Salón',
  'servicio': 'Servicio',
  'zona_comun': 'Zona común',
};

/// Etiqueta legible de un tipo. Un tipo nuevo que aún no esté en la tabla
/// no se muestra crudo: `sala_de_estudio` → "Sala de estudio".
String etiquetaTipo(String tipo) {
  final conocida = _etiquetas[tipo];
  if (conocida != null) return conocida;
  final texto = tipo.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (texto.isEmpty) return 'Sin tipo';
  return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
}

/// Colores del chip de iniciales de una zona: el tinte dice qué tipo de
/// lugar es (propuesta de interfaz, pantalla 2). Los tonos de texto de
/// zona común y servicio están oscurecidos respecto a la propuesta para
/// pasar 4,5:1 sobre su tinte.
class EstiloTipo {
  final Color fondo;
  final Color texto;
  const EstiloTipo(this.fondo, this.texto);
}

const estiloEdificio = EstiloTipo(Color(0xFFE6ECFF), ColoresMapsUtb.azul);
const estiloZonaComun = EstiloTipo(Color(0xFFDDF3EA), Color(0xFF016B47));
const estiloBiblioteca = EstiloTipo(Color(0xFFECE3FB), ColoresMapsUtb.morado);
const estiloServicio = EstiloTipo(Color(0xFFDDF6FC), Color(0xFF086A80));

EstiloTipo estiloTipo(String tipo) => switch (tipo) {
      'zona_comun' => estiloZonaComun,
      'biblioteca' => estiloBiblioteca,
      'servicio' || 'cafeteria' || 'parqueadero' => estiloServicio,
      _ => estiloEdificio,
    };

/// Iniciales para el chip de una zona: "A1" → "A1", "Zona T" → "ZT",
/// "Biblioteca Luis Enrique…" → "BI". Con dos palabras se toma la inicial
/// de cada una; si no, las dos primeras letras de la primera.
String inicialesZona(String nombre) {
  final palabras = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (palabras.isEmpty) return '?';
  if (palabras.length == 2) {
    return (palabras[0][0] + palabras[1][0]).toUpperCase();
  }
  final primera = palabras.first;
  return primera.substring(0, primera.length < 2 ? primera.length : 2).toUpperCase();
}

/// Resumen de una zona para listas y encabezados:
/// "Edificio · 5 pisos · 7 espacios", "Zona común · 6 espacios".
String resumenZona(Zona zona) {
  String contar(int n, String singular, String plural) => '$n ${n == 1 ? singular : plural}';
  return [
    etiquetaTipo(zona.tipo),
    if (zona.pisos.isNotEmpty) contar(zona.pisos.length, 'piso', 'pisos'),
    if (zona.espacios.isNotEmpty) contar(zona.espacios.length, 'espacio', 'espacios'),
  ].join(' · ');
}
