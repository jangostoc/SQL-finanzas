-- =====================================================================
-- MÓDULO 2 · Sumar y agrupar
-- SUM, ROUND, COUNT, COUNT(DISTINCT), GROUP BY, CASE WHEN, HAVING
-- Signos: saldo = debe - haber (gastos +, ingresos -). Ingresos en positivo: haber - debe
-- =====================================================================

-- 7. Cuadre del mayor: total debe = total haber
SELECT ROUND(SUM(debe), 2)  AS total_debe,
       ROUND(SUM(haber), 2) AS total_haber
FROM asientos;

-- 8. Gasto por cuenta
SELECT cuenta,
       ROUND(SUM(debe - haber), 2) AS gasto
FROM asientos
WHERE cuenta LIKE '6%'
GROUP BY cuenta
ORDER BY gasto DESC;

-- 9. Ventas por mes
--    Regla de oro: toda columna del SELECT que no esté en un SUM va en el GROUP BY
SELECT periodo,
       ROUND(SUM(haber - debe), 2) AS ventas
FROM asientos
WHERE cuenta IN ('700', '705')
GROUP BY periodo
ORDER BY periodo;

-- 10. Asientos (COUNT DISTINCT) frente a líneas (COUNT) por origen
SELECT origen,
       COUNT(DISTINCT id_asiento) AS num_asientos,
       COUNT(*)                   AS num_lineas
FROM asientos
GROUP BY origen
ORDER BY num_asientos DESC;

-- 11. Ingresos, gastos y resultado con CASE WHEN
SELECT
    ROUND(SUM(CASE WHEN cuenta LIKE '7%' THEN haber - debe ELSE 0 END), 2) AS ingresos,
    ROUND(SUM(CASE WHEN cuenta LIKE '6%' THEN debe - haber ELSE 0 END), 2) AS gastos,
    ROUND(SUM(CASE WHEN cuenta LIKE '7%' THEN haber - debe ELSE 0 END)
        - SUM(CASE WHEN cuenta LIKE '6%' THEN debe - haber ELSE 0 END), 2) AS resultado
FROM asientos;

-- 12. Centros de coste con gasto > 1.000.000 € (HAVING filtra grupos)
SELECT centro_coste,
       ROUND(SUM(debe - haber), 2) AS gasto
FROM asientos
WHERE cuenta LIKE '6%'
GROUP BY centro_coste
HAVING SUM(debe - haber) > 1000000;
