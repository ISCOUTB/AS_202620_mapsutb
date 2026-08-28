# Trazabilidad de Aspectos — MAPSUTB

Un aspecto es un corte vertical del sistema: aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia.

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|-----|-----|--------|---------|-----------|
| A-01 | Localización y guiado en tiempo real del usuario dentro del campus mediante realidad aumentada georreferenciada | RF-01: El sistema debe mostrar al usuario, sobre la cámara de su dispositivo, indicaciones visuales que lo guíen hacia un punto de interés seleccionado del campus. | Por definir (pendiente de modelado C4; se anticipa un contenedor tipo `app móvil (AR)` que consume un componente `servicio de ubicación/rutas` en el backend) | Sin ADR aún. Se anota el motivo: aún no se ha decidido la arquitectura general (nativo vs. multiplataforma, backend Node.js vs. Java), por lo que no existe una decisión estructural que documentar en esta entrega. | Aún no iniciado. | Aún no iniciado. | Aún no iniciado. |

## Escenario de calidad asociado a A-01 (formato de seis partes)

- **Fuente del estímulo:** un estudiante nuevo o visitante con la aplicación abierta en el campus.
- **Estímulo:** el usuario selecciona un punto de interés como destino (ej. "Bienestar Universitario").
- **Artefacto:** el módulo de guiado AR de la aplicación móvil.
- **Ambiente:** operación normal, en exteriores e interiores del campus, con señal GPS disponible.
- **Respuesta:** el sistema muestra la ubicacion del punto referenciado y superpone visuales de dirección sobre la cámara del dispositivo que muestre hacia donde tiene que ir el usuario.
- **Medida de respuesta:** la indicación visual aparece en un tiempo menor o igual a 3 segundos desde la selección del destino, con un margen de error de localización no mayor a 5 metros.

## Notas

- Este aspecto se declara como línea base para la entrega 1. Se espera completar las columnas C4, ADR, Código, Pruebas y Evidencia en los siguientes cortes incrementales.
- Aspectos candidatos adicionales identificados pero no priorizados aún para esta entrega: registro de puntos de interés, autenticación de usuarios invitados, navegación en interiores (fuera de alcance inicial).
