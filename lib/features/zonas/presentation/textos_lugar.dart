import 'package:mapsutb/l10n/app_localizations.dart';
import 'package:mapsutb/models/zona.dart';

/// Etiqueta traducida del tipo de una zona o de un espacio
/// ("Edificio", "laboratorio", "Zona Común"…).
///
/// Si llega un tipo que no está en la lista, se muestra tal cual (con la
/// primera letra en mayúscula) para que nunca quede vacío.
String etiquetaTipoL10n(AppLocalizations l10n, String tipo) {
  switch (_normalizar(tipo)) {
    case 'edificio':
      return l10n.tipoEdificio;
    case 'zona comun':
      return l10n.tipoZonaComun;
    case 'servicio':
      return l10n.tipoServicio;
    case 'biblioteca':
      return l10n.tipoBiblioteca;
    case 'salon':
      return l10n.tipoSalon;
    case 'laboratorio':
      return l10n.tipoLaboratorio;
    case 'oficina':
      return l10n.tipoOficina;
    case 'cafeteria':
      return l10n.tipoCafeteria;
    case 'auditorio':
      return l10n.tipoAuditorio;
  }
  final t = tipo.trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

/// Resumen traducido de una zona: "Edificio · 5 pisos · 7 espacios".
/// El bloque de pisos se omite cuando la zona no tiene pisos.
String resumenZonaL10n(AppLocalizations l10n, Zona zona) {
  return [
    etiquetaTipoL10n(l10n, zona.tipo),
    if (zona.pisos.isNotEmpty) l10n.cantidadPisos(zona.pisos.length),
    l10n.cantidadEspacios(zona.espacios.length),
  ].join(' · ');
}

/// Minúsculas, sin tildes y sin guiones bajos: "Zona Común" → "zona comun".
String _normalizar(String s) {
  const de = 'áéíóúü';
  const a = 'aeiouu';
  var r = s.trim().toLowerCase().replaceAll('_', ' ');
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], a[i]);
  }
  return r;
}