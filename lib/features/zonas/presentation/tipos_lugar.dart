import 'package:flutter/material.dart';
import 'package:mapsutb/l10n/app_localizations.dart';
import 'package:mapsutb/models/zona.dart';

import 'tema_maps_utb.dart';

/// Etiquetas en español para los valores de `tipo` de zonas.json (zonas y
/// espacios). Es el único lugar donde se traduce un tipo para mostrarlo.
String etiquetaTipo(String tipo) {
 const m={'auditorio':'Auditorio','biblioteca':'Biblioteca','cafeteria':'Cafeter?a','edificio':'Edificio','laboratorio':'Laboratorio','oficina':'Oficina','oficina_institucional':'Oficina institucional','parqueadero':'Parqueadero','salon':'Sal?n','servicio':'Servicio','zona_comun':'Zona com?n'};
 final v=m[tipo]; if(v!=null)return v; final t=tipo.replaceAll('_',' ').trim(); return t.isEmpty?'Sin tipo':t[0].toUpperCase()+t.substring(1).toLowerCase();
}

String etiquetaTipoLocalizada(BuildContext context, String tipo) {
  final l = AppLocalizations.of(context)!;
  final conocida = switch (tipo) {
    'auditorio' => l.auditorium, 'biblioteca' => l.library,
    'cafeteria' => l.cafeteria, 'edificio' => l.building,
    'laboratorio' => l.laboratory, 'oficina' => l.office,
    'oficina_institucional' => l.institutionalOffice,
    'parqueadero' => l.parking, 'salon' => l.classroom,
    'servicio' => l.service, 'zona_comun' => l.commonArea,
    _ => null,
  };
  if (conocida != null) return conocida;
  final texto = tipo.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (texto.isEmpty) return l.noType;
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
  String contar(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  return [etiquetaTipo(zona.tipo),
    if (zona.pisos.isNotEmpty) contar(zona.pisos.length, 'piso', 'pisos'),
    if (zona.espacios.isNotEmpty) contar(zona.espacios.length, 'espacio', 'espacios'),
  ].join(' ? ');
}
