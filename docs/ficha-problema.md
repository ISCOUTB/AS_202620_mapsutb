# Ficha del Problema

**Proyecto:** MAPSUTB: Mapa Interactivo de Ubicación con Recorrido panorámico 360°
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

El proyecto cubre navegación en exteriores mediante geolocalización y realidad aumentada. La navegación en interiores queda limitada en su alcance, pero sigue siendo funcional.

## APIs de Google consideradas

Maps SDK, ARCore Geospatial API, Places API, Directions API y Geocoding API, siendo la ARCore Geospatial API la de mayor relevancia para el componente de realidad aumentada georreferenciada.

## Arquitectura propuesta

**Frontend:** Flutter.
**Backend:** Ninguno. 

## Tensiones de calidad

**1. Precisión del ruteo vs. Simplicidad arquitectónica**
Un backend propio con motor de ruteo exacto mejoraría la precisión de las
rutas, pero incrementaría la complejidad de desarrollo y el tiempo de
entrega. Se prioriza la simplicidad: arquitectura monolito sin backend,
ruteo aproximado sobre el mapa local del campus.

**2. Actualización de ubicación en tiempo real vs. Eficiencia energética**
Mantener el GPS activo con actualizaciones frecuentes ofrece una guía más
precisa y fluida al usuario (posición actualizada al instante mientras
camina), pero consume batería y datos móviles más rápido. Se prioriza la
actualización en tiempo real, porque es indispensable para que el
usuario sepa dónde está y hacia dónde ir mientras se mueve por el
campus, aceptando el mayor consumo como costo del atributo priorizado.