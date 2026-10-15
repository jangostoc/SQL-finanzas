-- =====================================================================
-- MÓDULO 4 · Consultas por capas
-- WITH (CTE), varias CTE, subconsultas, CASE como tabla dinámica
-- =====================================================================

-- 19. Resultado con WITH (sin repetir fórmulas)
WITH totales AS (
    SELECT
        SUM(CASE WHEN cuenta LIKE '7%' THEN haber - debe ELSE 0 END) AS ingresos,
        SUM(CASE WHEN cuenta LIKE '6%' THEN debe - haber ELSE 0 END) AS gastos
    FROM asientos
)
SELECT ROUND(ingresos, 2)          AS ingresos,
       ROUND(gastos, 2)            AS gastos,
       ROUND(ingresos - gastos, 2) AS resultado
FROM totales;

-- 20. Líneas de la cuenta de resultados en columnas
SELECT
    ROUND(SUM(CASE WHEN p.linea_pyg = 'Ingresos'             THEN a.haber - a.debe ELSE 0 END), 2) AS ingresos,
    ROUND(SUM(CASE WHEN p.linea_pyg = 'Coste de ventas'      THEN a.debe - a.haber ELSE 0 END), 2) AS coste_ventas,
    ROUND(SUM(CASE WHEN p.linea_pyg = 'Gastos de personal'   THEN a.debe - a.haber ELSE 0 END), 2) AS personal,
    ROUND(SUM(CASE WHEN p.linea_pyg = 'Gastos operativos'    THEN a.debe - a.haber ELSE 0 END), 2) AS operativos,
    ROUND(SUM(CASE WHEN p.linea_pyg = 'Amortizaciones'       THEN a.debe - a.haber ELSE 0 END), 2) AS amortizaciones,
    ROUND(SUM(CASE WHEN p.linea_pyg = 'Resultado financiero' THEN a.debe - a.haber ELSE 0 END), 2) AS financieros
FROM asientos AS a
JOIN plan_cuentas AS p
  ON a.cuenta = p.cuenta;

-- 21. Cuenta de resultados con márgenes (Margen bruto, EBITDA, EBIT, Resultado)
WITH pyg AS (
    SELECT
        SUM(CASE WHEN p.linea_pyg = 'Ingresos'             THEN a.haber - a.debe ELSE 0 END) AS ingresos,
        SUM(CASE WHEN p.linea_pyg = 'Coste de ventas'      THEN a.debe - a.haber ELSE 0 END) AS coste_ventas,
        SUM(CASE WHEN p.linea_pyg = 'Gastos de personal'   THEN a.debe - a.haber ELSE 0 END) AS personal,
        SUM(CASE WHEN p.linea_pyg = 'Gastos operativos'    THEN a.debe - a.haber ELSE 0 END) AS operativos,
        SUM(CASE WHEN p.linea_pyg = 'Amortizaciones'       THEN a.debe - a.haber ELSE 0 END) AS amortizaciones,
        SUM(CASE WHEN p.linea_pyg = 'Resultado financiero' THEN a.debe - a.haber ELSE 0 END) AS financieros
    FROM asientos AS a
    JOIN plan_cuentas AS p
      ON a.cuenta = p.cuenta
)
SELECT
    ROUND(ingresos, 2)                                          AS ingresos,
    ROUND(ingresos - coste_ventas, 2)                           AS margen_bruto,
    ROUND(ingresos - coste_ventas - personal - operativos, 2)   AS ebitda,
    ROUND(ingresos - coste_ventas - personal - operativos
          - amortizaciones, 2)                                  AS ebit,
    ROUND(ingresos - coste_ventas - personal - operativos
          - amortizaciones - financieros, 2)                    AS resultado,
    ROUND((ingresos - coste_ventas) * 100.0 / ingresos, 1)      AS pct_margen_bruto,
    ROUND((ingresos - coste_ventas - personal - operativos)
          * 100.0 / ingresos, 1)                                AS pct_ebitda
FROM pyg;

-- 22. Cuenta de resultados mensual
WITH pyg AS (
    SELECT
        a.periodo,
        SUM(CASE WHEN p.linea_pyg = 'Ingresos'             THEN a.haber - a.debe ELSE 0 END) AS ingresos,
        SUM(CASE WHEN p.linea_pyg = 'Coste de ventas'      THEN a.debe - a.haber ELSE 0 END) AS coste_ventas,
        SUM(CASE WHEN p.linea_pyg = 'Gastos de personal'   THEN a.debe - a.haber ELSE 0 END) AS personal,
        SUM(CASE WHEN p.linea_pyg = 'Gastos operativos'    THEN a.debe - a.haber ELSE 0 END) AS operativos
    FROM asientos AS a
    JOIN plan_cuentas AS p
      ON a.cuenta = p.cuenta
    GROUP BY a.periodo
)
SELECT
    periodo,
    ROUND(ingresos, 2)                                        AS ingresos,
    ROUND(ingresos - coste_ventas, 2)                         AS margen_bruto,
    ROUND(ingresos - coste_ventas - personal - operativos, 2) AS ebitda
FROM pyg
ORDER BY periodo;

-- 23. % de gasto por departamento (subconsulta como divisor)
SELECT cc.nombre AS departamento,
       ROUND(SUM(a.debe - a.haber), 2) AS gasto,
       ROUND(SUM(a.debe - a.haber) * 100.0
             / (SELECT SUM(debe - haber)
                FROM asientos
                WHERE cuenta LIKE '6%'), 1) AS pct_total
FROM asientos AS a
JOIN centros_coste AS cc
  ON a.centro_coste = cc.centro_coste
WHERE a.cuenta LIKE '6%'
GROUP BY cc.nombre
ORDER BY gasto DESC;

-- 24. Real vs presupuesto por línea (dos CTE unidas con JOIN)
WITH real AS (
    SELECT p.linea_pyg,
           SUM(CASE WHEN p.tipo = 'Ingreso' THEN a.haber - a.debe
                    ELSE a.debe - a.haber END) AS importe
    FROM asientos AS a
    JOIN plan_cuentas AS p
      ON a.cuenta = p.cuenta
    WHERE p.linea_pyg IS NOT NULL
    GROUP BY p.linea_pyg
),
ppto AS (
    SELECT p.linea_pyg,
           SUM(b.importe) AS importe
    FROM presupuesto AS b
    JOIN plan_cuentas AS p
      ON b.cuenta = p.cuenta
    GROUP BY p.linea_pyg
)
SELECT r.linea_pyg,
       ROUND(r.importe, 2)                                    AS real,
       ROUND(pp.importe, 2)                                   AS presupuesto,
       ROUND(r.importe - pp.importe, 2)                       AS desviacion,
       ROUND((r.importe - pp.importe) * 100.0 / pp.importe, 1) AS pct_desviacion
FROM real AS r
JOIN ppto AS pp
  ON r.linea_pyg = pp.linea_pyg;
