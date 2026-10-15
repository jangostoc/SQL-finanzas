-- =====================================================================
-- 02. Cuenta de resultados mensual con márgenes y acumulado del año
-- ---------------------------------------------------------------------
-- Una fila por mes: ingresos, margen bruto, EBITDA y resultado, con su
-- % sobre ventas y el resultado acumulado YTD.
--
-- Técnicas: CTE, JOIN, CASE (pivot), funciones de ventana (SUM OVER).
-- =====================================================================

WITH pyg AS (
    SELECT
        a.periodo,
        SUM(CASE WHEN p.linea_pyg = 'Ingresos'             THEN a.haber - a.debe ELSE 0 END) AS ingresos,
        SUM(CASE WHEN p.linea_pyg = 'Coste de ventas'      THEN a.debe - a.haber ELSE 0 END) AS coste_ventas,
        SUM(CASE WHEN p.linea_pyg = 'Gastos de personal'   THEN a.debe - a.haber ELSE 0 END) AS personal,
        SUM(CASE WHEN p.linea_pyg = 'Gastos operativos'    THEN a.debe - a.haber ELSE 0 END) AS operativos,
        SUM(CASE WHEN p.linea_pyg = 'Amortizaciones'       THEN a.debe - a.haber ELSE 0 END) AS amortizaciones,
        SUM(CASE WHEN p.linea_pyg = 'Resultado financiero' THEN a.debe - a.haber ELSE 0 END) AS financieros
    FROM asientos AS a
    JOIN plan_cuentas AS p
      ON a.cuenta = p.cuenta
    WHERE p.linea_pyg IS NOT NULL
    GROUP BY a.periodo
),

margenes AS (
    SELECT periodo,
           ingresos,
           ingresos - coste_ventas                                   AS margen_bruto,
           ingresos - coste_ventas - personal - operativos           AS ebitda,
           ingresos - coste_ventas - personal - operativos
                    - amortizaciones - financieros                   AS resultado
    FROM pyg
)

SELECT periodo,
       ROUND(ingresos, 2)                               AS ingresos,
       ROUND(margen_bruto, 2)                           AS margen_bruto,
       ROUND(margen_bruto * 100.0 / ingresos, 1)        AS pct_margen_bruto,
       ROUND(ebitda, 2)                                 AS ebitda,
       ROUND(ebitda * 100.0 / ingresos, 1)              AS pct_ebitda,
       ROUND(resultado, 2)                              AS resultado,
       ROUND(SUM(resultado) OVER (ORDER BY periodo), 2) AS resultado_ytd
FROM margenes
ORDER BY periodo;
