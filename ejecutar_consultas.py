"""
Ejecuta todas las consultas .sql de un proyecto sobre la base de datos
de práctica y guarda cada resultado como CSV en su carpeta `resultados/`.

Uso:
    python ejecutar_consultas.py                      # todos los proyectos
    python ejecutar_consultas.py 01-pyg-real-vs-presupuesto
"""
import csv
import sqlite3
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent
DB = RAIZ / "datos" / "erp_practica.db"


def ejecutar_proyecto(carpeta: Path, con: sqlite3.Connection) -> None:
    salida = carpeta / "resultados"
    salida.mkdir(exist_ok=True)
    for sql_file in sorted((carpeta / "sql").glob("*.sql")):
        cur = con.execute(sql_file.read_text(encoding="utf-8"))
        columnas = [d[0] for d in cur.description]
        filas = cur.fetchall()
        destino = salida / f"{sql_file.stem}.csv"
        # Separador ';' y codificación utf-8-sig para que Excel en español lo abra bien
        with destino.open("w", newline="", encoding="utf-8-sig") as f:
            w = csv.writer(f, delimiter=";")
            w.writerow(columnas)
            w.writerows(filas)
        print(f"  {sql_file.name:45s} -> {len(filas):3d} filas")


def main() -> None:
    if not DB.exists():
        sys.exit("No existe la base de datos. Ejecuta antes: python datos/generar_erp.py")
    proyectos = [RAIZ / a for a in sys.argv[1:]] or sorted(
        p for p in RAIZ.iterdir() if p.is_dir() and (p / "sql").is_dir()
    )
    with sqlite3.connect(DB) as con:
        for proyecto in proyectos:
            print(proyecto.name)
            ejecutar_proyecto(proyecto, con)


if __name__ == "__main__":
    main()
