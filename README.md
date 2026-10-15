# SQL para finanzas · FP&A y control de gestión

Proyectos de SQL aplicados al trabajo de un **analista FP&A / controller financiero**: extraer información contable de un ERP y transformarla en informes de gestión (cuenta de resultados, presupuesto, cierre mensual, tesorería).

Todos los proyectos trabajan sobre la misma base de datos, que simula la contabilidad de 2025 de una empresa española con plan contable al estilo PGC.

## Proyectos

| # | Proyecto | Perfil | Estado |
|---|---|---|---|
| 1 | [Cuenta de resultados: real vs presupuesto](01-pyg-real-vs-presupuesto/) | FP&A | ✅ |
| 2 | Checklist de cierre mensual: cuadres y controles de calidad del dato | Controller | 🔜 |
| 3 | Antigüedad de saldos de clientes (aging) y previsión de tesorería | Controller / Tesorería | 🔜 |

## Los datos

`datos/erp_practica.db` es una base de datos SQLite que reproduce las tablas típicas que se extraen de un ERP:

| Tabla | Contenido | Filas |
|---|---|---:|
| `asientos` | Libro mayor: una fila por línea de asiento (fecha, cuenta, centro de coste, debe, haber, concepto, origen) | 3.142 |
| `plan_cuentas` | Plan contable con tipo de cuenta y su línea en la cuenta de resultados | 16 |
| `centros_coste` | Departamentos y área a la que pertenecen | 5 |
| `presupuesto` | Presupuesto mensual por cuenta y centro de coste | 300 |

```
plan_cuentas ──┐                 ┌── centros_coste
  (cuenta)     │                 │   (centro_coste)
               ▼                 ▼
            asientos  ◄────►  presupuesto
       (libro mayor, real)   (por cuenta y centro de coste)
```

La base se genera de forma reproducible con [`datos/generar_erp.py`](datos/generar_erp.py): ventas con estacionalidad, compras, nóminas con Seguridad Social, gastos de estructura, amortizaciones, cobros y pagos. El mayor cuadra (total debe = total haber).

## Ejercicios

En [`ejercicios/`](ejercicios/) está el recorrido de aprendizaje que sirve de base a los proyectos: 30 ejercicios resueltos, organizados por módulos.

| Módulo | Contenido |
|---|---|
| [1 · Consultar y filtrar](ejercicios/modulo_1_consultar_y_filtrar.sql) | `SELECT`, `WHERE`, `IN`, `LIKE`, `IS NULL`, `ORDER BY` |
| [2 · Sumar y agrupar](ejercicios/modulo_2_sumar_y_agrupar.sql) | `SUM`, `COUNT`, `GROUP BY`, `CASE WHEN`, `HAVING` |
| [3 · Unir tablas](ejercicios/modulo_3_unir_tablas.sql) | `JOIN`, `LEFT JOIN`, uniones de varias tablas |
| [4 · Consultas por capas](ejercicios/modulo_4_consultas_por_capas.sql) | `WITH` (CTE), subconsultas, márgenes de la cuenta de resultados |
| [5 · Funciones de ventana](ejercicios/modulo_5_funciones_de_ventana.sql) | `SUM OVER` (YTD), `LAG`, `RANK`, medias móviles |

## Cómo usarlo

**Opción 1 · Con un editor SQL.** Abre `datos/erp_practica.db` en [DBeaver](https://dbeaver.io/) o [DB Browser for SQLite](https://sqlitebrowser.org/) y ejecuta cualquier archivo `.sql`.

**Opción 2 · Con Python** (solo usa la librería estándar):

```bash
python datos/generar_erp.py      # (opcional) regenera la base de datos
python ejecutar_consultas.py     # ejecuta las consultas y guarda los CSV en resultados/
```

## Convenciones contables

- Saldo de una cuenta en el mayor: `debe − haber` (gastos positivos, ingresos negativos).
- Para los informes, los ingresos se expresan en positivo con `haber − debe`.
- El presupuesto está siempre en positivo, tanto ingresos como gastos.
- Las cuentas de balance (clientes, bancos, proveedores, amortización acumulada) no llevan centro de coste.

## Herramientas

SQL (dialecto SQLite, compatible en lo esencial con SQL Server y PostgreSQL) · DBeaver · Python 3
