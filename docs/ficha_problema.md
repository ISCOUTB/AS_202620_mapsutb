# Ficha del Problema

**Proyecto:** MAPSUTB: Mapa Interactivo de Ubicación con Recorrido panorámico 360° 
**Curso:** AS_202620_MAPSUTB — Organización ISCOUTB
**Integrantes:** Carlos Galvis Zuluaga, Carlos Manrique Fals, Nerlis Otero Perez, Isabel Paez Matallana
**Repositorio:** AS_202620_MAPSUTB

## Problema

Los estudiantes nuevos, los estudiantes de intercambio y los visitantes invitados a eventos presentan dificultades para orientarse dentro del campus universitario, lo que genera pérdida de tiempo, confusión y una experiencia inicial deficiente.

## Objetivo general

Desarrollar una aplicación móvil que combine un mapa interactivo del campus con un recorrido panorámico 360° para guiar a los usuarios hacia edificios, aulas, oficinas o puntos de interés dentro de la universidad.

## Objetivos específicos

- Ubicar al usuario en tiempo real dentro del campus.
- Mostrar rutas hacia un destino específico sobre el plano del campus.
- Ofrecer un recorrido panorámico 360° de puntos de interés del campus.
- Registrar puntos de interés del campus.

## Alcance

El proyecto cubre navegación en exteriores mediante geolocalización sobre un plano propio del campus superpuesto a un mapa base (Google Maps SDK), y un recorrido panorámico 360° de puntos de interés. La navegación en interiores queda limitada en su alcance, pero sigue siendo funcional. No se implementa guiado por realidad aumentada sobre cámara: se evaluó ARCore Geospatial API y se descartó por completo — ver ADR 0003 para el razonamiento.

## APIs de Google consideradas

Maps SDK (mapa base) y Geocoding API (conversión de coordenadas y direcciones) son las dos que el proyecto usa. Se evaluaron también ARCore Geospatial API, Places API y Directions API, pero se descartaron por el cambio de alcance documentado en el ADR 0003.

## Arquitectura propuesta

**Frontend:** Flutter. **Backend:** Ninguno.

## Tensiones de calidad

**1. Precisión del ruteo vs. Simplicidad arquitectónica**
Un backend propio con motor de ruteo exacto mejoraría la precisión de las rutas, pero incrementaría la complejidad de desarrollo y el tiempo de entrega. Se prioriza la simplicidad: arquitectura monolito sin backend, ruteo aproximado sobre el mapa local del campus.

**2. Actualización de ubicación en tiempo real vs. Eficiencia energética**
Mantener el GPS activo con actualizaciones frecuentes ofrece una guía más precisa y fluida al usuario (posición actualizada al instante mientras camina), pero consume batería y datos móviles más rápido. Se prioriza la actualización en tiempo real, porque es indispensable para que el usuario sepa dónde está y hacia dónde ir mientras se mueve por el campus, aceptando el mayor consumo como costo del atributo priorizado.
