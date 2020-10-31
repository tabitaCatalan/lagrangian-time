#=
Este archivo intenta una nueva versión del modelo usando Callbacks

Callback Library:
https://diffeq.sciml.ai/dev/features/callback_library/#callback_library

Specific Array Types
https://diffeq.sciml.ai/dev/features/diffeq_arrays/#control_problem
=#

using TimeSeries
using SQLite
using DataFrames

"""
    contar_dias(TS::TimeSeries)
Cuenta la cantidad de días de una serie de tiempo
"""
contar_dias(TS::TimeArray) = length(timestamp(TS))

"""
    read_data_cuarentena(csv_cuarentena; delim = ';')
# Argumentos
- `csv_cuarentena::String`: path al csv con la serie de tiempo correspondiente a la cuarentena por dia y comuna.
# Salida
- `data_cuarentena::TimeSeries`  (fechas en las filas, comunas en las columnas)
- `numero_dias`: cuantos dias están considerados en los datos.
# Ejemplo
```julia
data_cuarentenas, numero_dias = read_data_cuarentena('..\\..\\data\\CuarentenasRM.csv'; delim = ';')
```
"""
function read_data_cuarentena(csv_cuarentena; delim = ';')
    data_cuarentenas = readtimearray(csv_cuarentena; delim = delim)
    numero_dias = contar_dias(data_cuarentenas)
    data_cuarentenas, numero_dias
end

"""
    read_db(eod_db, sql_query)
Ejecuta una consulta a una base de datos
# Argumentos
- `eod_db::String`: path a la base de datos EOD
- `sql_query::String`: path al archivo con la consulta SQL.
# Resultados
- `result_df::DataFrame`: con los resultados de la consulta.
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


"""
    calcular_pobla_en_cuarentena(tiempo, data_cuarentenas, df)
Calcula la cantidad de personas que están en cuarentena en cierto tiempo.
"""
function calcular_pobla_en_cuarentena_en_t(t_floor, data_cuarentenas, df)
    cuarentenas_en_t = values(data_cuarentenas[t_floor])'
    comunas_sin_cuarentena = [34, 42, 44, 46, 47, 50]
    f = i -> in(i, comunas_sin_cuarentena)
    comunas_con_cuarentena = .!f.(1:52)
    pobla_por_comuna = df.poblacion_total
    pobla_en_cuarentena = similar(pobla_por_comuna)
    pobla_en_cuarentena[comunas_sin_cuarentena] .= 0
    pobla_en_cuarentena[comunas_con_cuarentena] = pobla_por_comuna[comunas_con_cuarentena] .* cuarentenas_en_t
    pobla_en_cuarentena
end


"""
    calcular_frac_cuarentena_en_t!(frac, tiempo)
Calcula la fracción de personas en cuarentena.
# Argumentos
- `frac`: array preallocated. Aquí se guarda la solución.
- `tiempo`: debe ser menor que la variable `numero_dias`
- `data_cuarentenas::TimeSeries`
- `df::DataFrame`
Se usan los siguientes datos:
┌───────────────┬─────────────────┬───────────────────┐
│ tramo_pobreza │ poblacion_total │  frac_poblacion   │
├───────────────┼─────────────────┼───────────────────┤
│ 1             │ 2456390         │ 0.345347435218271 │
│ 2             │ 3071158         │ 0.431778560590979 │
│ 3             │ 1585260         │ 0.22287400419075  │
└───────────────┴─────────────────┴───────────────────┘
"""
function calcular_frac_cuarentena_en_t_por_tramo!(frac, tiempo, data_cuarentenas, df)
    t_floor = floor(Int, tiempo)
    pobla_en_cuarentena = calcular_pobla_en_cuarentena_en_t(t_floor, data_cuarentenas, df)
    frac_t1 = sum(pobla_en_cuarentena[df.tramo_pobreza .== 1])/2456390
    frac_t2 = sum(pobla_en_cuarentena[df.tramo_pobreza .== 2])/3071158
    frac_t3 = sum(pobla_en_cuarentena[df.tramo_pobreza .== 3])/1585260
    frac[t_floor,1] = frac_t1
    frac[t_floor,2] = frac_t2
    frac[t_floor,3] = frac_t3
end

"""
    calcular_frac_cuarentena(data_cuarentenas, df)
Devuelve un array con la cantidad de personas en cuarentena cada día.
"""
function calcular_frac_cuarentena(data_cuarentenas, df)
    numero_dias = contar_dias(data_cuarentenas)
    total_pobla_cuarentena_en_t(dia) = sum(calcular_pobla_en_cuarentena_en_t(dia, data_cuarentenas, df))
    pobla_en_cuarentena = total_pobla_cuarentena_en_t.(1:numero_dias)
    frac = pobla_en_cuarentena ./ sum(df.poblacion_total)
    frac
end



"""
    calcular_frac_cuarentena(df, numero_dias)
# Argumentos
- `numero_dias`
- `data_cuarentenas::TimeSeries`
- `df::DataFrame`
"""
function calcular_frac_cuarentena_por_tramo(data_cuarentenas, df)
    numero_dias = contar_dias(data_cuarentenas)
    frac = zeros(numero_dias, 3)
    for i in 1:numero_dias
        calcular_frac_cuarentena_en_t_por_tramo!(frac,i, data_cuarentenas, df)
    end
    frac
end

"""
    obtener_frac_cuarentena_from_csv(csv_cuarentena, eod_db, pobla_query, delim = ';')
# Argumentos
Calcula la fracción de personas en cuarentena para todos los dias disponibles en el csv.
- `csv_cuarentena::String`: path al csv con la serie de tiempo correspondiente a la cuarentena por dia y comuna.
Se espera que sea de la forma
```
fecha; comuna_1; comuna_2; ...
2020-03-27; 0;1;
```
La fecha debe estar en formato `YYYY-MM-DD`. Los datos son binarios, indicando si la comuna se encontraba o no en cuarentena ese día.
- `eod_db::String`: path a la base de datos EOD
- `pobla_query::String`: path al archivo con la consulta SQL.
- `delim = ';'`: (opcional) delimitador del `.csv` con los datos de las cuarentenas.
- `tramos::Bool`: si `true`, devuelve un array de 3 columnas, con los resultados separados por tramo.
# Ejemplo
frac_cuarentena = obtener_frac_cuarentena_from_csv('CuarentenaRM.csv', 'EOD2012-Santiago.db', 'query-poblacion-clase.sql')
"""
function obtener_frac_cuarentena_from_csv(csv_cuarentena, eod_db, pobla_query; delim = ';', tramos = true)
    data_cuarentenas, numero_dias = read_data_cuarentena(csv_cuarentena; delim = delim)
    tramos_df = read_db(eod_db, pobla_query)
    if tramos
        frac = calcular_frac_cuarentena_por_tramo(data_cuarentenas, tramos_df)
    else
        frac = calcular_frac_cuarentena(data_cuarentenas, tramos_df)
    end
    frac, timestamp(data_cuarentenas)
end
