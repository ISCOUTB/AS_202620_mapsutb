# Ficha del Problema

**Proyecto:** MAPSUTB: Mapa Interactivo de Ubicación con Realidad Aumentada
**Curso:** AS_202620_MAPSUTB — Organización ISCOUTB
**Integrantes:** Carlos Galvis zuluaga, Carlos Manrique Fals, Nerlis Otero Perez, Isabel Paez Matallana
**Repositorio:** AS_202620_MAPSUTB

## Problema

Los estudiantes nuevos, los estudiantes de intercambio y los visitantes invitados a eventos presentan dificultades para orientarse dentro del campus universitario, lo que genera pérdida de tiempo, confusión y una experiencia inicial deficiente.

## Objetivo general

Desarrollar una aplicación móvil que combine mapas digitales y realidad aumentada para guiar a los usuarios hacia edificios, aulas, oficinas o puntos de interés dentro de la universidad.

## Objetivos específicos

- Ubicar al usuario en tiempo real dentro del campus.
- Mostrar rutas hacia un destino específico.
- Superponer indicaciones visuales de realidad aumentada sobre la cámara del dispositivo.
- Registrar puntos de interés del campus.

## Alcance

El proyecto cubre navegación en exteriores mediante geolocalización y realidad aumentada. La navegación en interiores queda fuera del alcance inicial y se documenta como limitación.

## APIs de Google consideradas

Maps SDK, ARCore Geospatial API, Places API, Directions API y Geocoding API, siendo la ARCore Geospatial API la de mayor relevancia para el componente de realidad aumentada georreferenciada.

## Arquitectura propuesta

**Frontend:** Flutter.
**Backend:** Node.js 
