# Escenarios de calidad medibles — MAPSUTB

| # | Escenario | Medida de respuesta |
|---|---|---|
| 1 | Un usuario abre un punto del tour con conexión 4G y la escena panorámica se carga y renderiza completamente. | Menos de 3 segundos. |
| 2 | Un usuario solicita una ruta hacia un punto del campus en exteriores; el sistema calcula y muestra la ruta. | Menos de 5 segundos, con margen de error de ubicación menor a 10 metros. |
| 3 | La conexión a internet se interrumpe o se degrada mientras se usa la app. | 0% de caídas de la app; 100% de los casos con mensaje de error controlado. |
| 4 | Un usuario nuevo abre la app por primera vez, sin instrucciones, e intenta moverse de un punto a otro del campus. | Lo logra en menos de 2 minutos, sin ayuda externa. |
| 5 | Se revisa un punto capturado (panorámica) contra el espacio real correspondiente durante la validación de contenido. | Mínimo 90% de los puntos aprobados sin necesidad de recaptura. |

> Estos escenarios operacionalizan el [árbol de utilidad](./02_arbol_utilidad.md) definido para el proyecto.
