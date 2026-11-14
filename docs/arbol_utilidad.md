# Árbol de utilidad — MAPSUTB

Derivado de los objetivos de calidad definidos en la sección 1.2 de la documentación Arc42.

- **Usabilidad** → navegación intuitiva sin instrucciones; consistencia de interfaz; interfaz multilenguaje (español/inglés; pendiente: solo español hoy)
- **Rendimiento** → tiempo hasta ver la ruta tras elegir el destino (Escenario 2); tiempo de carga de escenas panorámicas y fluidez (FPS) en dispositivos gama media (Escenario 1, diferido con el tour)
- **Disponibilidad / confiabilidad** → manejo adecuado de conexión lenta, interrumpida o offline (Escenario 3); disponibilidad del sitio publicado (Escenario 6); reversión rápida de un despliegue roto (Escenario 7).
- **Precisión de geolocalización y ruteo** → exactitud de ubicación en exteriores del campus (los interiores quedan fuera de alcance: la ruta termina en la entrada); corrección del trazado de ruta (Escenario 2)
- **Portabilidad** → compatibilidad con navegadores de computador y celular y con distintos tamaños de pantalla (web en Firebase Hosting; compilación móvil no configurada)
- **Mantenibilidad** → facilidad para actualizar manualmente la clasificación de zonas del campus
- **Fidelidad de contenido** → correspondencia entre el contenido virtual (zonas y grafo; el tour 360° está diferido, Escenario 5) y los espacios reales de la UTB

> Los escenarios de calidad medibles derivados de este árbol se documentan en [`escenarios_calidad.md`](./escenarios_calidad.md).
