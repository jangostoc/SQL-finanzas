-- =====================================================================
-- MÓDULO 3 · Unir tablas
-- JOIN (INNER), LEFT JOIN, alias de tabla, JOIN de 3 tablas
-- =====================================================================

-- 13. Libro mayor con nombre de cuenta
SELECT a.fecha, a.cuenta, p.nombre, a.debe, a.haber
FROM asientos AS a
JOIN plan_cuentas AS p
  ON a.cuenta = p.cuenta
LIMIT 10;

-- 14. Gasto por cuenta con nombre
SELECT a.cuenta, p.nombre,
       ROUND(SUM(a.debe - a.haber), 2) AS gasto
FROM asientos AS a
JOIN plan_cuentas AS p
  ON a.cuenta = p.cuenta
WHERE p.tipo = 'Gasto'
GROUP BY a.cuenta, p.nombre
ORDER BY gasto DESC;

-- 15. Gasto por departamento
SELECT cc.nombre AS departamento,
       ROUND(SUM(a.debe - a.haber), 2) AS gasto
FROM asientos AS a
JOIN centros_coste AS cc
  ON a.centro_coste = cc.centro_coste
WHERE a.cuenta LIKE '6%'
GROUP BY cc.nombre
ORDER BY gasto DESC;

-- 16. Primera cuenta de resultados por línea (la suma da el resultado del año)
SELECT p.linea_pyg,
       ROUND(SUM(a.haber - a.debe), 2) AS importe
FROM asientos AS a
JOIN plan_cuentas AS p
  ON a.cuenta = p.cuenta
WHERE p.linea_pyg IS NOT NULL
GROUP BY p.linea_pyg
ORDER BY importe DESC;

-- 17. Gasto por área (JOIN de tres tablas)
SELECT cc.area,
       ROUND(SUM(a.debe - a.haber), 2) AS gasto
FROM asientos AS a
JOIN plan_cuentas AS p
  ON a.cuenta = p.cuenta
JOIN centros_coste AS cc
  ON a.centro_coste = cc.centro_coste
WHERE p.tipo = 'Gasto'
GROUP BY cc.area
ORDER BY gasto DESC;

-- 18a. INNER JOIN: solo las líneas con centro de coste (1.044)
SELECT COUNT(*) AS num_lineas
FROM asientos AS a
JOIN centros_coste AS cc
  ON a.centro_coste = cc.centro_coste;

-- 18b. LEFT JOIN: todas las líneas del mayor (3.142)
--      Lección: comparar siempre los totales antes y después de un JOIN
SELECT COUNT(*) AS num_lineas
FROM asientos AS a
LEFT JOIN centros_coste AS cc
  ON a.centro_coste = cc.centro_coste;
