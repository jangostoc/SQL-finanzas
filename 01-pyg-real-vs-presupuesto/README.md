# Proyecto 1 · Cuenta de resultados: real vs presupuesto

Informe de **FP&A** construido íntegramente en SQL a partir del libro mayor de un ERP: cuenta de pérdidas y ganancias con márgenes, comparación con el presupuesto, evolución mensual y análisis de desviaciones por departamento.

## Pregunta de negocio

> *La empresa ha vendido más de lo presupuestado en 2025. ¿Por qué entonces el resultado ha quedado por debajo del objetivo, y dónde hay que actuar?*

## Resultado principal

| Concepto | Real (€) | Presupuesto (€) | Desviación (€) | % | Valoración |
|---|---:|---:|---:|---:|---|
| Ingresos | 6.532.341 | 6.413.000 | +119.341 | +1,9 % | Favorable |
| Coste de ventas | 2.209.331 | 2.129.600 | +79.731 | +3,7 % | Desfavorable |
| **Margen bruto** | **4.323.011** | **4.283.400** | **+39.611** | **+0,9 %** | Favorable |
| Gastos de personal | 2.822.422 | 2.776.800 | +45.622 | +1,6 % | Desfavorable |
| Gastos operativos | 694.063 | 685.500 | +8.563 | +1,2 % | Desfavorable |
| **EBITDA** | **806.526** | **821.100** | **−14.574** | **−1,8 %** | Desfavorable |
| Amortizaciones | 146.110 | 144.000 | +2.110 | +1,5 % | Desfavorable |
| **EBIT** | **660.416** | **677.100** | **−16.684** | **−2,5 %** | Desfavorable |
| Resultado financiero | 30.855 | 30.000 | +855 | +2,8 % | Desfavorable |
| **RESULTADO** | **629.561** | **647.100** | **−17.539** | **−2,7 %** | Desfavorable |

*Salida de [`sql/01_pyg_real_vs_presupuesto.sql`](sql/01_pyg_real_vs_presupuesto.sql).*

## Conclusiones

1. **El margen bruto se estrecha.** Las ventas crecen un 1,9 % sobre presupuesto, pero el coste de ventas lo hace un 3,7 %. El margen bruto cae del 66,8 % presupuestado al 66,2 % real: cada euro vendido ha costado más de lo previsto.
2. **La estructura no se ha ajustado.** Personal (+45.622 €) y gastos operativos (+8.563 €) superan el presupuesto y se comen el exceso de margen bruto. El EBITDA queda un 1,8 % por debajo.
3. **Fuerte estacionalidad y apalancamiento operativo.** Enero y agosto cierran con EBITDA negativo: con las ventas más bajas del año, los costes fijos no se cubren. Diciembre, el mejor mes, aporta un EBITDA del 26 % sobre ventas.
4. **La ventaja en ventas se diluye en el segundo semestre.** El acumulado de ventas llegó a ir 142.000 € por encima del presupuesto en julio, pero cierra el año en 119.000 €: de agosto a diciembre se vendió algo menos de lo previsto.
5. **Dónde actuar.** La mayor desviación absoluta está en **Operaciones · compras de mercaderías** (+79.731 €, +3,7 %). Le siguen los sueldos de Administración y Operaciones (unos +10.600 € cada uno) y la **Seguridad Social a cargo de la empresa**, que se desvía más que los sueldos en todos los departamentos (hasta +6,4 %). Eso apunta a un error de hipótesis en el presupuesto: se presupuestó al 30 % de los sueldos y el coste real ronda el 31 %.

## Consultas

| Archivo | Qué responde | Técnicas SQL |
|---|---|---|
| [`01_pyg_real_vs_presupuesto.sql`](sql/01_pyg_real_vs_presupuesto.sql) | Cuenta de resultados anual con márgenes, desviaciones y su valoración | CTE encadenadas, `CASE`, `UNION ALL`, `MAX() OVER ()` |
| [`02_pyg_mensual.sql`](sql/02_pyg_mensual.sql) | Márgenes mes a mes y resultado acumulado | `CASE` como tabla dinámica, `SUM() OVER (ORDER BY)` |
| [`03_ventas_ytd_vs_presupuesto.sql`](sql/03_ventas_ytd_vs_presupuesto.sql) | Ventas reales vs presupuesto, mensual y YTD, con variación y media móvil | `LAG`, `SUM() OVER`, `AVG() OVER (ROWS BETWEEN)` |
| [`04_desviaciones_por_departamento.sql`](sql/04_desviaciones_por_departamento.sql) | Desviaciones de gasto por departamento y cuenta, ordenadas por importe | `LEFT JOIN`, `COALESCE`, `NULLIF`, `RANK() OVER (PARTITION BY)` |

Los resultados de cada consulta están en [`resultados/`](resultados/) en formato CSV (separador `;`, se abre directamente en Excel).

## Decisiones de diseño

- **Signos.** En el mayor el saldo es `debe − haber`. Para comparar con el presupuesto (siempre en positivo), todo el informe trabaja con importes positivos: ingresos como `haber − debe` y gastos como `debe − haber`.
- **Valoración automática.** Cada línea lleva una "naturaleza" (+1 si más es mejor, −1 si más es peor). Así una desviación positiva se marca como favorable en ingresos y márgenes, y como desfavorable en gastos.
- **`LEFT JOIN` en el análisis por departamento.** Una partida con gasto real y sin presupuesto no debe desaparecer del informe: es justo la desviación que más interesa explicar.
- **`NULLIF` en los porcentajes.** Evita errores de división por cero cuando una partida no está presupuestada.

## Cómo reproducirlo

Desde la raíz del repositorio:

```bash
python ejecutar_consultas.py 01-pyg-real-vs-presupuesto
```

O abre `datos/erp_practica.db` en DBeaver o DB Browser for SQLite y ejecuta cada archivo `.sql`.
