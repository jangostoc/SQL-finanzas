-- =====================================================================
-- MÓDULO 5 · Funciones de ventana
-- SUM OVER, LAG, RANK con PARTITION BY, AVG OVER con ROWS BETWEEN
-- =====================================================================

-- 25. Ventas acumuladas del año (YTD)
WITH ventas_mes AS (
    SELECT periodo, SUM(haber - debe) AS ventas
    FROM asientos
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
)
SELECT periodo,
       ROUND(ventas, 2) AS ventas,
       ROUND(SUM(ventas) OVER (ORDER BY periodo), 2) AS ventas_ytd
FROM ventas_mes
ORDER BY periodo;

-- 26. Variación frente al mes anterior (LAG)
WITH ventas_mes AS (
    SELECT periodo, SUM(haber - debe) AS ventas
    FROM asientos
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
)
SELECT periodo,
       ROUND(ventas, 2) AS ventas,
       ROUND(LAG(ventas) OVER (ORDER BY periodo), 2) AS ventas_mes_anterior,
       ROUND((ventas - LAG(ventas) OVER (ORDER BY periodo)) * 100.0
             / LAG(ventas) OVER (ORDER BY periodo), 1) AS pct_variacion
FROM ventas_mes
ORDER BY periodo;

-- 27. Peso de cada mes sobre el total anual (SUM OVER () = total en cada fila)
WITH ventas_mes AS (
    SELECT periodo, SUM(haber - debe) AS ventas
    FROM asientos
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
)
SELECT periodo,
       ROUND(ventas, 2) AS ventas,
       ROUND(SUM(ventas) OVER (), 2) AS ventas_anuales,
       ROUND(ventas * 100.0 / SUM(ventas) OVER (), 1) AS pct_sobre_anual
FROM ventas_mes
ORDER BY periodo;

-- 28. Mayor partida de gasto de cada centro de coste
--     No se puede filtrar una función de ventana en el WHERE: se filtra en otra capa
WITH gasto_cc AS (
    SELECT centro_coste, cuenta, SUM(debe - haber) AS gasto
    FROM asientos
    WHERE cuenta LIKE '6%'
    GROUP BY centro_coste, cuenta
),
ranking_cc AS (
    SELECT centro_coste, cuenta, gasto,
           RANK() OVER (PARTITION BY centro_coste ORDER BY gasto DESC) AS ranking
    FROM gasto_cc
)
SELECT centro_coste, cuenta, ROUND(gasto, 2) AS gasto
FROM ranking_cc
WHERE ranking = 1;

-- 29. Media móvil de 3 meses
WITH ventas_mes AS (
    SELECT periodo, SUM(haber - debe) AS ventas
    FROM asientos
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
)
SELECT periodo,
       ROUND(ventas, 2) AS ventas,
       ROUND(AVG(ventas) OVER (ORDER BY periodo
                               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movil_3m
FROM ventas_mes
ORDER BY periodo;

-- 30. Ventas YTD real vs presupuesto
WITH real AS (
    SELECT periodo, SUM(haber - debe) AS ventas_real
    FROM asientos
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
),
ppto AS (
    SELECT periodo, SUM(importe) AS ventas_ppto
    FROM presupuesto
    WHERE cuenta IN ('700', '705')
    GROUP BY periodo
)
SELECT r.periodo,
       ROUND(SUM(r.ventas_real) OVER (ORDER BY r.periodo), 2) AS real_ytd,
       ROUND(SUM(p.ventas_ppto) OVER (ORDER BY r.periodo), 2) AS ppto_ytd,
       ROUND(SUM(r.ventas_real) OVER (ORDER BY r.periodo)
           - SUM(p.ventas_ppto) OVER (ORDER BY r.periodo), 2) AS desviacion_ytd
FROM real AS r
JOIN ppto AS p
  ON r.periodo = p.periodo
ORDER BY r.periodo;
