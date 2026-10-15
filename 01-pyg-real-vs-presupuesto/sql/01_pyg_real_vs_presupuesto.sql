-- =====================================================================
-- 01. Cuenta de resultados anual: real vs presupuesto
-- ---------------------------------------------------------------------
-- Construye la cuenta de pérdidas y ganancias en su orden "de libro"
-- (Ingresos -> Margen bruto -> EBITDA -> EBIT -> Resultado), compara
-- real con presupuesto y marca cada desviación como favorable o no.
--
-- Técnicas: CTE encadenadas, JOIN, CASE, UNION ALL.
-- Convención: todos los importes en positivo (ingresos y gastos).
-- =====================================================================

WITH
-- 1) Real por línea de la cuenta de resultados, en positivo
real AS (
    SELECT p.linea_pyg,
           SUM(CASE WHEN p.tipo = 'Ingreso' THEN a.haber - a.debe
                    ELSE a.debe - a.haber END) AS importe
    FROM asientos AS a
    JOIN plan_cuentas AS p
      ON a.cuenta = p.cuenta
    WHERE p.linea_pyg IS NOT NULL
    GROUP BY p.linea_pyg
),

-- 2) Presupuesto por línea (la tabla ya viene en positivo)
ppto AS (
    SELECT p.linea_pyg,
           SUM(b.importe) AS importe
    FROM presupuesto AS b
    JOIN plan_cuentas AS p
      ON b.cuenta = p.cuenta
    GROUP BY p.linea_pyg
),

-- 3) Pasamos las líneas a columnas: una fila con real y otra con presupuesto
escenarios AS (
    SELECT 'real' AS escenario,
           SUM(CASE WHEN linea_pyg = 'Ingresos'             THEN importe ELSE 0 END) AS ingresos,
           SUM(CASE WHEN linea_pyg = 'Coste de ventas'      THEN importe ELSE 0 END) AS coste_ventas,
           SUM(CASE WHEN linea_pyg = 'Gastos de personal'   THEN importe ELSE 0 END) AS personal,
           SUM(CASE WHEN linea_pyg = 'Gastos operativos'    THEN importe ELSE 0 END) AS operativos,
           SUM(CASE WHEN linea_pyg = 'Amortizaciones'       THEN importe ELSE 0 END) AS amortizaciones,
           SUM(CASE WHEN linea_pyg = 'Resultado financiero' THEN importe ELSE 0 END) AS financieros
    FROM real
    UNION ALL
    SELECT 'ppto',
           SUM(CASE WHEN linea_pyg = 'Ingresos'             THEN importe ELSE 0 END),
           SUM(CASE WHEN linea_pyg = 'Coste de ventas'      THEN importe ELSE 0 END),
           SUM(CASE WHEN linea_pyg = 'Gastos de personal'   THEN importe ELSE 0 END),
           SUM(CASE WHEN linea_pyg = 'Gastos operativos'    THEN importe ELSE 0 END),
           SUM(CASE WHEN linea_pyg = 'Amortizaciones'       THEN importe ELSE 0 END),
           SUM(CASE WHEN linea_pyg = 'Resultado financiero' THEN importe ELSE 0 END)
    FROM ppto
),

-- 4) Calculamos los márgenes de cada escenario
margenes AS (
    SELECT escenario,
           ingresos,
           coste_ventas,
           ingresos - coste_ventas                                   AS margen_bruto,
           personal,
           operativos,
           ingresos - coste_ventas - personal - operativos           AS ebitda,
           amortizaciones,
           ingresos - coste_ventas - personal - operativos
                    - amortizaciones                                 AS ebit,
           financieros,
           ingresos - coste_ventas - personal - operativos
                    - amortizaciones - financieros                   AS resultado
    FROM escenarios
),

-- 5) Volvemos a poner cada concepto en una fila, con su orden y su naturaleza
--    naturaleza = +1 si más es mejor (ingresos, márgenes); -1 si más es peor (gastos)
lineas AS (
    SELECT 1 AS orden, 'Ingresos' AS concepto, 1 AS naturaleza, escenario, ingresos AS importe FROM margenes
    UNION ALL SELECT 2,  'Coste de ventas',      -1, escenario, coste_ventas   FROM margenes
    UNION ALL SELECT 3,  'MARGEN BRUTO',          1, escenario, margen_bruto   FROM margenes
    UNION ALL SELECT 4,  'Gastos de personal',   -1, escenario, personal       FROM margenes
    UNION ALL SELECT 5,  'Gastos operativos',    -1, escenario, operativos     FROM margenes
    UNION ALL SELECT 6,  'EBITDA',                1, escenario, ebitda         FROM margenes
    UNION ALL SELECT 7,  'Amortizaciones',       -1, escenario, amortizaciones FROM margenes
    UNION ALL SELECT 8,  'EBIT',                  1, escenario, ebit           FROM margenes
    UNION ALL SELECT 9,  'Resultado financiero', -1, escenario, financieros    FROM margenes
    UNION ALL SELECT 10, 'RESULTADO',             1, escenario, resultado      FROM margenes
),

-- 6) Real y presupuesto lado a lado
comparativa AS (
    SELECT orden, concepto, naturaleza,
           SUM(CASE WHEN escenario = 'real' THEN importe END) AS real,
           SUM(CASE WHEN escenario = 'ppto' THEN importe END) AS presupuesto
    FROM lineas
    GROUP BY orden, concepto, naturaleza
)

SELECT concepto,
       ROUND(real, 2)                                       AS real,
       ROUND(presupuesto, 2)                                AS presupuesto,
       ROUND(real - presupuesto, 2)                         AS desviacion,
       ROUND((real - presupuesto) * 100.0 / presupuesto, 1) AS pct_desviacion,
       CASE WHEN (real - presupuesto) * naturaleza >= 0
            THEN 'Favorable' ELSE 'Desfavorable' END         AS valoracion,
       ROUND(real * 100.0
             / MAX(CASE WHEN orden = 1 THEN real END) OVER (), 1)        AS pct_s_ventas_real,
       ROUND(presupuesto * 100.0
             / MAX(CASE WHEN orden = 1 THEN presupuesto END) OVER (), 1) AS pct_s_ventas_ppto
FROM comparativa
ORDER BY orden;
