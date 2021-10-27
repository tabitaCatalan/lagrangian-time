# Funciones útiles para importar datos desde archivos csv, bases de datos, etc.
using SQLite, DataFrames

"""
    read_db(eod_db, sql_query)
Ejecuta una consulta a una base de datos
# Argumentos
- `eod_db::String`: path a la base de datos EOD
- `sql_query::String`: path al archivo con la consulta SQL.
# Resultados
- `result_df::DataFrame`: con los resultados de la consulta.
# Ejemplos
```julia
poblacion_db_file = "data\\poblacion\\poblacion.db"
query_file = "data\\poblacion\\edades.sql"
poblacion = read_db(poblacion_db_file, query_file)
```
"""
function read_db(eod_db, sql_query)
    DB_EOD =  SQLite.DB(eod_db)

    # Leer consulta SQL del archivo y guardar como String
    io = open(sql_query)
    sql = read(io, String)
    close(io)

    result_df = DataFrame(DBInterface.execute(DB_EOD, sql))
    result_df
end
