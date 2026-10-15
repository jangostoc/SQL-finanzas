"""
Genera erp_practica.db: una base SQLite que simula los datos contables
de una empresa española (año 2025) extraídos de un ERP.

Tablas:
  plan_cuentas      -> plan contable (estilo PGC)
  centros_coste     -> centros de coste / departamentos
  asientos          -> libro mayor (una fila por línea de asiento)
  presupuesto       -> presupuesto mensual por cuenta y centro de coste
"""
import random
import sqlite3
from datetime import date, timedelta

random.seed(42)
import os
DB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "erp_practica.db")

plan_cuentas = [
    # cuenta, nombre, tipo, linea_pyg
    ("700", "Ventas de mercaderías", "Ingreso", "Ingresos"),
    ("705", "Prestación de servicios", "Ingreso", "Ingresos"),
    ("600", "Compras de mercaderías", "Gasto", "Coste de ventas"),
    ("621", "Arrendamientos", "Gasto", "Gastos operativos"),
    ("623", "Servicios profesionales", "Gasto", "Gastos operativos"),
    ("627", "Publicidad", "Gasto", "Gastos operativos"),
    ("628", "Suministros", "Gasto", "Gastos operativos"),
    ("629", "Otros servicios", "Gasto", "Gastos operativos"),
    ("640", "Sueldos y salarios", "Gasto", "Gastos de personal"),
    ("642", "Seguridad Social empresa", "Gasto", "Gastos de personal"),
    ("681", "Amortización inmovilizado", "Gasto", "Amortizaciones"),
    ("662", "Intereses de deudas", "Gasto", "Resultado financiero"),
    ("430", "Clientes", "Activo", None),
    ("572", "Bancos", "Activo", None),
    ("281", "Amortización acumulada", "Activo", None),
    ("400", "Proveedores", "Pasivo", None),
]

centros_coste = [
    ("CC100", "Comercial", "Ventas"),
    ("CC200", "Operaciones", "Operaciones"),
    ("CC300", "Marketing", "Ventas"),
    ("CC400", "Administración", "G&A"),
    ("CC500", "IT", "G&A"),
]

# Gasto mensual base por (cuenta, centro de coste)
gastos_base = {
    ("621", "CC400"): 12000, ("621", "CC200"): 8000,
    ("623", "CC400"): 6000, ("623", "CC500"): 4000,
    ("627", "CC300"): 15000,
    ("628", "CC200"): 5000, ("628", "CC400"): 1500,
    ("629", "CC500"): 3500, ("629", "CC100"): 2000,
    ("640", "CC100"): 45000, ("640", "CC200"): 60000, ("640", "CC300"): 18000,
    ("640", "CC400"): 30000, ("640", "CC500"): 25000,
    ("681", "CC200"): 9000, ("681", "CC500"): 3000,
    ("662", "CC400"): 2500,
}
estacionalidad = [0.85, 0.85, 0.95, 1.0, 1.05, 1.1, 1.0, 0.75, 1.05, 1.1, 1.15, 1.25]

con = sqlite3.connect(DB)
cur = con.cursor()
cur.executescript("""
DROP TABLE IF EXISTS plan_cuentas;
DROP TABLE IF EXISTS centros_coste;
DROP TABLE IF EXISTS asientos;
DROP TABLE IF EXISTS presupuesto;

CREATE TABLE plan_cuentas (
    cuenta TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL,          -- Ingreso / Gasto / Activo / Pasivo
    linea_pyg TEXT               -- agrupación de la cuenta de resultados (NULL si es de balance)
);
CREATE TABLE centros_coste (
    centro_coste TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    area TEXT NOT NULL
);
CREATE TABLE asientos (
    id_asiento INTEGER NOT NULL,
    linea INTEGER NOT NULL,
    fecha TEXT NOT NULL,         -- YYYY-MM-DD
    periodo TEXT NOT NULL,       -- YYYY-MM
    cuenta TEXT NOT NULL REFERENCES plan_cuentas(cuenta),
    centro_coste TEXT REFERENCES centros_coste(centro_coste),
    debe REAL NOT NULL DEFAULT 0,
    haber REAL NOT NULL DEFAULT 0,
    concepto TEXT,
    origen TEXT,                 -- VENTAS / COMPRAS / NOMINA / GASTOS / CIERRE
    PRIMARY KEY (id_asiento, linea)
);
CREATE TABLE presupuesto (
    periodo TEXT NOT NULL,
    cuenta TEXT NOT NULL REFERENCES plan_cuentas(cuenta),
    centro_coste TEXT NOT NULL REFERENCES centros_coste(centro_coste),
    importe REAL NOT NULL,       -- en positivo, tanto ingresos como gastos
    PRIMARY KEY (periodo, cuenta, centro_coste)
);
""")
cur.executemany("INSERT INTO plan_cuentas VALUES (?,?,?,?)", plan_cuentas)
cur.executemany("INSERT INTO centros_coste VALUES (?,?,?)", centros_coste)

lineas = []
id_asiento = 0

def asiento(fecha, origen, concepto, movimientos):
    """movimientos: lista de (cuenta, centro_coste, debe, haber)"""
    global id_asiento
    id_asiento += 1
    for n, (cta, cc, d, h) in enumerate(movimientos, start=1):
        lineas.append((id_asiento, n, fecha.isoformat(), fecha.strftime("%Y-%m"),
                       cta, cc, round(d, 2), round(h, 2), concepto, origen))

def fecha_aleatoria(mes):
    inicio = date(2025, mes, 1)
    fin = date(2025, mes + 1, 1) if mes < 12 else date(2026, 1, 1)
    return inicio + timedelta(days=random.randrange((fin - inicio).days))

presupuesto = []
for mes in range(1, 13):
    periodo = f"2025-{mes:02d}"
    est = estacionalidad[mes - 1]

    # --- Ventas: ~60 facturas al mes ---
    ventas_mes = {"700": 0, "705": 0}
    for _ in range(60):
        cta = random.choice(["700", "700", "700", "705"])
        imp = round(random.uniform(4000, 14000) * est, 2)
        f = fecha_aleatoria(mes)
        ventas_mes[cta] += imp
        asiento(f, "VENTAS", f"Factura cliente {random.randint(1000, 1099)}",
                [("430", None, imp, 0), (cta, "CC100", 0, imp)])
        if random.random() < 0.8:  # cobro
            asiento(f + timedelta(days=random.randint(15, 60)), "VENTAS", "Cobro cliente",
                    [("572", None, imp, 0), ("430", None, 0, imp)])

    # --- Compras de mercaderías: ~45% de las ventas de 700 ---
    compras = ventas_mes["700"] * random.uniform(0.42, 0.50)
    for parte in range(5):
        imp = round(compras / 5, 2)
        f = fecha_aleatoria(mes)
        asiento(f, "COMPRAS", f"Factura proveedor {random.randint(2000, 2049)}",
                [("600", "CC200", imp, 0), ("400", None, 0, imp)])
        asiento(f + timedelta(days=30), "COMPRAS", "Pago proveedor",
                [("400", None, imp, 0), ("572", None, 0, imp)])

    # --- Gastos de estructura ---
    for (cta, cc), base in gastos_base.items():
        f = date(2025, mes, 28)
        imp = round(base * random.uniform(0.92, 1.12), 2)
        if cta == "627":
            imp = round(imp * est * random.uniform(0.8, 1.4), 2)  # marketing más volátil
        if cta == "640":
            ss = round(imp * 0.31, 2)
            asiento(f, "NOMINA", f"Nómina {periodo} {cc}",
                    [("640", cc, imp, 0), ("642", cc, ss, 0), ("572", None, 0, imp + ss)])
        elif cta == "681":
            asiento(date(2025, mes, 28), "CIERRE", f"Amortización {periodo}",
                    [("681", cc, imp, 0), ("281", None, 0, imp)])
        else:
            asiento(f, "GASTOS", f"Gasto {cta} {periodo}",
                    [(cta, cc, imp, 0), ("400", None, 0, imp)])

    # --- Presupuesto (elaborado "antes" del año) ---
    for cta, base in (("700", 400000), ("705", 130000)):
        presupuesto.append((periodo, cta, "CC100", round(base * est, 2)))
    presupuesto.append((periodo, "600", "CC200", round(400000 * est * 0.44, 2)))
    for (cta, cc), base in gastos_base.items():
        imp = base * (est if cta == "627" else 1)
        presupuesto.append((periodo, cta, cc, round(imp, 2)))
        if cta == "640":
            presupuesto.append((periodo, "642", cc, round(imp * 0.30, 2)))

# Solo dejamos asientos con fecha de 2025 (algunos cobros/pagos caerían en 2026)
lineas = [l for l in lineas if l[2] < "2026-01-01"]
cur.executemany("INSERT INTO asientos VALUES (?,?,?,?,?,?,?,?,?,?)", lineas)
cur.executemany("INSERT INTO presupuesto VALUES (?,?,?,?)", presupuesto)
con.commit()

for t in ("plan_cuentas", "centros_coste", "asientos", "presupuesto"):
    print(t, cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0])
con.close()
