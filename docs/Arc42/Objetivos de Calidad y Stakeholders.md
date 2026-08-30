# MAPSUTB: Mapa Interactivo de Ubicación con Realidad Aumentada
## Documentación Arc42

# Introducción y objetivos

## Descripción general

**MAPSUTB** es una aplicación móvil desarrollada en Flutter que permite a distintos tipos de usuarios explorar el campus de la *Universidad Tecnológica de Bolívar* (UTB) mediante recorridos panoramicos 360° anclados a ubicaciones reales del campus. El proyecto se desarrolla dentro de la organización de GitHub ISCOUTB, como parte del curso académico de *Arquitectura de Software*.

El sistema utiliza un sistema de recorridos en 360° y un mapa de la universidad para mostrar la ubicacion de los puntos de interes de la misma, permitiendole al usuario no perderse a la hora de llegar a la universidad y poder encontrar el lugar que busca.

## Objetivos de calidad

A partir del árbol de utilidad elaborado para el proyecto, se priorizaron los siguientes atributos de calidad:

| Atributo de calidad | Motivación / prioridad |
|---|---|
| Rendimiento | La experiencia de tour panorámico depende de cargas rápidas y de mantener FPS estables en dispositivos de gama media. |
| Precisión de geolocalización y ruteo | Es el diferenciador central del producto (posición del usuario en tiempo real vía GPS); errores de precisión degradan directamente el valor de la app. |
| Disponibilidad / confiabilidad | La app no depende exclusivamente a tener una conexion a internet, mientras tenga acceso a la ubicacion, deberia funcionar. |
| Usabilidad | El público incluye aspirantes que usan la app por primera vez e invitados a la universidad, sin guía previa. |
| Fidelidad de contenido | El tour debe representar fielmente los espacios reales, dado su uso institucional potencial. |
| Mantenibilidad | La clasificación de zonas es manual; debe ser sencilla de actualizar por el equipo. |
| Portabilidad | Debe funcionar en distintas versiones y tamaños de pantalla de Android/iOS. |


> El detalle del árbol de utilidad se encuentra en [`arbol_utilidad.md`](./arbol_utilidad.md) y los escenarios de calidad medibles en [`escenarios_calidad.md`](./escenarios_calidad.md).

## Interesados (stakeholders)

| Interesado | Rol | Interés / expectativa principal |
|---|---|---|
| Aspirantes / futuros estudiantes | Usuario final primario | Conocer las ubicaciones importantes del campus antes de matricularse; experiencia fluida. |
| Invitados | Usuario final secundario | Poder explorar el campus y ubicarse |
| Estudiantes actuales | Usuario final secundario | Ubicarse y trazar rutas dentro del campus. |
| Estudiantes de intercambio extranjeros | Usuario final secundario | Interfaz en inglés; orientarse en un campus desconocido sin barrera de idioma. |
| UTB (Admisiones / Bienestar Universitario) | Cliente institucional | Representación fiel del campus; herramienta de inclusión de estudiantes. |
| Docente(s) del curso | Evaluador académico | Cumplimiento de la metodología arc42/C4 y de los entregables definidos. |
| Equipo de desarrollo | Desarrolladores | Arquitectura mantenible; cumplir los plazos del semestre. |
| Organización ISCOUTB (GitHub) | Repositorio / comunidad técnica | Buenas prácticas y documentación clara para dar continuidad al proyecto. |
| Futuros mantenedores (próximos semestres) | Interesados indirectos | Código y arquitectura entendibles para continuar el desarrollo. |
| APIs públicas de Google (terceros) | Proveedor de servicios | Disponibilidad y estabilidad de los servicios consumidos por la app. |

