-- =====================================================================
-- 03. Ventas: real vs presupuesto, mes a mes y acumulado (YTD)
-- ---------------------------------------------------------------------
-- Responde a la pregunta típica del cierre mensual:
-- "¿cómo vamos este mes y en lo que llevamos de año frente al presupuesto?"
-- Incluye la variación frente al mes anterior y una media móvil de 3 meses.
--
-- Técnicas: CTE, JOIN, LAG, SUM OVER (acumulado), AVG OVER (media móvil).
-- =====================================================================

WITH real AS (
    SELECT periodo,
           SUM(haber - debe) AS ventas_real
    FROM asientos
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
),

ppto AS (
    SELECT periodo,
           SUM(importe) AS ventas_ppto
    FROM presupuesto
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
),

mensual AS (
    SELECT r.periodo,
           r.ventas_real,
           p.ventas_ppto,
           SUM(r.ventas_real) OVER (ORDER BY r.periodo) AS real_ytd,
           SUM(p.ventas_ppto) OVER (ORDER BY r.periodo) AS ppto_ytd,
           LAG(r.ventas_real) OVER (ORDER BY r.periodo) AS real_mes_anterior,
           AVG(r.ventas_real) OVER (ORDER BY r.periodo
                                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movil_3m
    FROM real AS r
    JOIN ppto AS p
      ON r.periodo = p.periodo
)

SELECT periodo,
       ROUND(ventas_real, 2)                                            AS ventas_real,
       ROUND(ventas_ppto, 2)                                            AS ventas_ppto,
       ROUND(ventas_real - ventas_ppto, 2)                              AS desviacion_mes,
       ROUND((ventas_real - ventas_ppto) * 100.0 / ventas_ppto, 1)      AS pct_desviacion_mes,
       ROUND(real_ytd, 2)                                               AS real_ytd,
       ROUND(ppto_ytd, 2)                                               AS ppto_ytd,
       ROUND(real_ytd - ppto_ytd, 2)                                    AS desviacion_ytd,
       ROUND((ventas_real - real_mes_anterior) * 100.0
             / real_mes_anterior, 1)                                    AS pct_var_mes_anterior,
       ROUND(media_movil_3m, 2)                                         AS media_movil_3m
FROM mensual
ORDER BY periodo;
