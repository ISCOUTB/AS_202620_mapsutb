"""Pruebas del análisis del Escenario 6 (S14). Se ejecutan en CI con
`python -m unittest discover -s scripts/medicion`."""
import json
import unittest
from datetime import datetime, timedelta, timezone

from analizar_disponibilidad import leer, p95, resumir, ventanas

INICIO = datetime(2026, 11, 1, tzinfo=timezone.utc)


def muestra(horas, disponible=True, ms_health=100, ms_sitio=200):
    ts = (INICIO + timedelta(hours=horas)).strftime("%Y-%m-%dT%H:%M:%SZ")
    return json.dumps({"ts": ts, "http_sitio": 200 if disponible else 0, "ms_sitio": ms_sitio,
                       "http_health": 200 if disponible else 0, "ms_health": ms_health,
                       "disponible": disponible})


class AnalisisDisponibilidad(unittest.TestCase):
    def test_p95_por_rango_mas_cercano(self):
        self.assertEqual(p95(list(range(1, 101))), 95)
        self.assertEqual(p95([7]), 7)
        self.assertIsNone(p95([]))

    def test_una_caida_cuenta_en_la_disponibilidad_y_en_el_p95(self):
        lineas = [muestra(h) for h in range(99)] + [muestra(99, disponible=False, ms_health=15000)]
        fila = resumir(INICIO, INICIO + timedelta(days=7), leer(lineas))
        self.assertEqual(fila["muestras"], 100)
        self.assertEqual(fila["esperadas"], 168)
        self.assertEqual(fila["caidas"], 1)
        self.assertEqual(fila["disponibilidad_pct"], 99.0)
        self.assertEqual(fila["max_health_ms"], 15000)
        self.assertTrue(fila["cumple"])

    def test_no_cumple_si_el_p95_del_health_llega_a_un_segundo(self):
        lineas = [muestra(h, ms_health=1000) for h in range(20)]
        fila = resumir(INICIO, INICIO + timedelta(days=7), leer(lineas))
        self.assertEqual(fila["p95_health_ms"], 1000)
        self.assertFalse(fila["cumple"])

    def test_solo_cuenta_ventanas_completas_hacia_atras(self):
        # 10 días de muestras: cabe una ventana completa de 7 días; los 3 primeros días sobran.
        muestras = leer([muestra(h) for h in range(24 * 10)])
        filas = ventanas(muestras, INICIO + timedelta(days=10))
        self.assertEqual(len(filas), 1)
        self.assertEqual(filas[0]["desde"], "2026-11-04T00:00:00Z")
        self.assertEqual(filas[0]["muestras"], 168)


if __name__ == "__main__":
    unittest.main()
