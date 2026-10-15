-- =====================================================================
-- 04. Desviaciones de gasto por departamento y cuenta
-- ---------------------------------------------------------------------
-- Detalla dónde se ha gastado más (o menos) de lo presupuestado y
-- ordena las desviaciones de mayor a menor importe dentro de cada
-- departamento, para saber qué preguntar a cada responsable.
--
-- Técnicas: CTE, LEFT JOIN, JOIN de 3 tablas, RANK con PARTITION BY.
-- =====================================================================

WITH real AS (
    SELECT a.centro_coste,
           a.cuenta,
           SUM(a.debe - a.haber) AS gasto_real
    FROM asientos AS a
    JOIN plan_cuentas AS p
      ON a.cuenta = p.cuenta
    WHERE p.tipo = 'Gasto'
    GROUP BY a.centro_coste, a.cuenta
),

ppto AS (
    SELECT b.centro_coste,
           b.cuenta,
           SUM(b.importe) AS gasto_ppto
    FROM presupuesto AS b
    JOIN plan_cuentas AS p
      ON b.cuenta = p.cuenta
    WHERE p.tipo = 'Gasto'
    GROUP BY b.centro_coste, b.cuenta
),

-- LEFT JOIN: si una partida tiene gasto real pero no presupuesto,
-- no queremos perderla (sería justo la desviación más interesante).
comparativa AS (
    SELECT r.centro_coste,
           r.cuenta,
           r.gasto_real,
           COALESCE(pp.gasto_ppto, 0)                AS gasto_ppto,
           r.gasto_real - COALESCE(pp.gasto_ppto, 0) AS desviacion
    FROM real AS r
    LEFT JOIN ppto AS pp
      ON  r.centro_coste = pp.centro_coste
      AND r.cuenta       = pp.cuenta
)

SELECT cc.nombre                                          AS departamento,
       c.cuenta,
       p.nombre                                           AS nombre_cuenta,
       ROUND(c.gasto_real, 2)                             AS gasto_real,
       ROUND(c.gasto_ppto, 2)                             AS gasto_ppto,
       ROUND(c.desviacion, 2)                             AS desviacion,
       ROUND(c.desviacion * 100.0
             / NULLIF(c.gasto_ppto, 0), 1)                AS pct_desviacion,
       CASE WHEN c.desviacion > 0 THEN 'Sobrecoste'
            ELSE 'Ahorro' END                             AS valoracion,
       RANK() OVER (PARTITION BY c.centro_coste
                    ORDER BY ABS(c.desviacion) DESC)      AS ranking_en_departamento
FROM comparativa AS c
JOIN centros_coste AS cc
  ON c.centro_coste = cc.centro_coste
JOIN plan_cuentas AS p
  ON c.cuenta = p.cuenta
ORDER BY departamento, ranking_en_departamento;
