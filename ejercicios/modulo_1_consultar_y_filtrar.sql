-- =====================================================================
-- MÓDULO 1 · Consultar y filtrar
-- SELECT, FROM, WHERE, AND, IN, LIKE, IS NULL, DISTINCT, ORDER BY, LIMIT
-- =====================================================================

-- 1. Ver las primeras líneas del libro mayor
SELECT *
FROM asientos
LIMIT 10;

-- 2. Cuentas de gasto del plan contable, ordenadas
SELECT *
FROM plan_cuentas
WHERE tipo = 'Gasto'
ORDER BY cuenta;

-- 3. Gasto de publicidad (627) de marzo de 2025
SELECT fecha, cuenta, centro_coste, debe, haber, concepto
FROM asientos
WHERE cuenta = '627'
  AND periodo = '2025-03';

-- 4. Las 5 mayores facturas de venta del año
SELECT fecha, cuenta, haber, concepto
FROM asientos
WHERE cuenta IN ('700', '705')
ORDER BY haber DESC
LIMIT 5;

-- 5. Líneas de nómina (3 líneas por asiento: 640, 642 y 572)
SELECT fecha, cuenta, centro_coste, debe, haber, concepto
FROM asientos
WHERE concepto LIKE '%Nómina%';

-- 6. Cuentas sin centro de coste (son las de balance)
--    Ojo: "= NULL" no funciona, hay que usar "IS NULL"
SELECT DISTINCT cuenta
FROM asientos
WHERE centro_coste IS NULL;
