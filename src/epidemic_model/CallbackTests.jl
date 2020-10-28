#=
Este archivo intenta una nueva versión del modelo usando Callbacks

Callback Library:
https://diffeq.sciml.ai/dev/features/callback_library/#callback_library

Specific Array Types
https://diffeq.sciml.ai/dev/features/diffeq_arrays/#control_problem
=#

using ComponentArrays
using DifferentialEquations
using StaticArrays # creo que no aporta mucho...
using TimeSeries
using SQLite
using DataFrames

"""
    read_data_cuarentena(csv_cuarentena; delim = ';')
# Argumentos 
- `csv_cuarentena::String`: path al csv con la serie de tiempo correspondientes a la cuarentena por dia y comuna. 
Se espera que sea de la forma 
```
fecha; comuna_1; comuna_2; ...
2020-03-27; 0;1;
```
La fecha debe estar en formato `YYYY-MM-DD`. Los datos son binarios, indicando si la comuna se encontraba o no en cuarentena ese día.
- `delim = ';'`: opcional, delimitador de columna usado en el csv.
"""
function read_data_cuarentena(csv_cuarentena; delim = ';')
    data_cuarentenas = readtimearray(csv_cuarentena; delim = delim)
    numero_dias = length(timestamp(data_cuarentenas))
    data_cuarentenas, numero_dias
end
data_cuarentenas, numero_dias = read_data_cuarentena("..\\..\\data\\CuarentenasRM.csv")

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

tramos_df = read_db("..\\..\\data\\EOD2012-Santiago.db", "query-poblacion-clase.sql")
tramo_pobreza = tramos_df.tramo_pobreza # tramos por comuna
pobla_por_comuna = tramos_df.poblacion_total


"""
    calcular_frac_en_cuarentena!(frac, tiempo)
Calcula la fracción de personas en cuarentena.
# Argumentos
- `frac`: array preallocated. Aquí se guarda la solución.
- `tiempo`: debe ser menor que la variable `numero_dias`
Se usan los siguientes datos:
┌───────────────┬─────────────────┬───────────────────┐
│ tramo_pobreza │ poblacion_total │  frac_poblacion   │
├───────────────┼─────────────────┼───────────────────┤
│ 1             │ 2456390         │ 0.345347435218271 │
│ 2             │ 3071158         │ 0.431778560590979 │
│ 3             │ 1585260         │ 0.22287400419075  │
└───────────────┴─────────────────┴───────────────────┘
"""
function calcular_frac_en_cuarentena!(frac, tiempo)
    t_floor = floor(Int, tiempo)
    cuarentenas_en_t = values(data_cuarentenas[t_floor])'
    comunas_sin_cuarentena = [34, 42, 44, 46, 47, 50]
    f = i -> in(i, comunas_sin_cuarentena)
    comunas_con_cuarentena = .!f.(1:52)
    pobla_en_cuarentena = similar(pobla_por_comuna)
    pobla_en_cuarentena[comunas_sin_cuarentena] .= 0
    pobla_en_cuarentena[comunas_con_cuarentena] = pobla_por_comuna[comunas_con_cuarentena] .* cuarentenas_en_t
    frac_t1 = sum(pobla_en_cuarentena[tramo_pobreza .== 1])/2456390
    frac_t2 = sum(pobla_en_cuarentena[tramo_pobreza .== 2])/3071158
    frac_t3 = sum(pobla_en_cuarentena[tramo_pobreza .== 3])/1585260
    frac[t_floor,1] = frac_t1 
    frac[t_floor,2] = frac_t2
    frac[t_floor,3] = frac_t3
end

frac = zeros(numero_dias, 3)
for i in 1:numero_dias
    calcular_frac_en_cuarentena!(frac,i)
end


"""
    matrix_ponderation!(P, P_normal, P_cuarentena, frac_cuarentena_por_clase)
Recibe la fracción de personas en cuarentena en cada clase social. Devuelve la
matriz P que es una ponderación de la matriz P en condiciones normales y en
cuarentena.
# Argumentos 
- `P`: preallocated matrix 
    Para guardar el resultado
- `P_normal:` matrix de tiempos de residencia normal 
- `P_cuarentena`: matriz de tiempos de residencia en cuarentena total
- `frac_cuarentena_por_clase`: fracción de personas en cuarentena por clase 
    - `frac_cuarentena_por_clase[1]`: clase baja
    - `frac_cuarentena_por_clase[2]`: clase media
    - `frac_cuarentena_por_clase[3]`: clase alta
"""
function matrix_ponderation!(P, P_normal, P_cuarentena, frac_cuarentena_por_clase)
    mapping = @SArray [1,1,2,2,3,3,1,1,2,2,3,3,1,1,2,2,3,3] # 0.000022 seconds  (4 allocations: 6.062 KiB)
    # mapping = [1,1,2,2,3,3,1,1,2,2,3,3,1,1,2,2,3,3] # 0.000017 seconds (7 allocations: 6.719 KiB)
    P .= frac_cuarentena_por_clase[mapping] .* P_cuarentena + (1 .- frac_cuarentena_por_clase[mapping]) .* P_normal
end

#P = similar(P_normal)
#matrix_ponderation!(P, P_normal, P_cuarentena, [frac_t1, frac_t2, frac_t3])

"""
    MyDataArray
Esta estructura está pensada para ser usada en el modelo de **EpidemicModel.jl**. Surge de la necesidad de tener acceso a variables globales eficientes. Puede usarse en el solver de **DifferentialEquations.jl**.
# Campos
- `x`: Estado actual
- `P_normal`: matriz de tiempos de residencia normal 
    (sin medidas preventivas)
- `P_cuarentena`: matriz de tiempos de residencia en
    cuarentena. Del mismo tamaño que `P_normal`.
- `frac_pobla_cuarentena`: matriz de fraccion de personas 
    en cuarentena dependiendo del tiempo. Es de tamño `numero_dias`x3. En la coordenada `i,j` contiene la 
    fracción de personas de la clase social `j` que están
    en cuarentena el día `i`.
"""
struct MyDataArray{T} <: DEDataArray{T,1}
    x::ComponentArray{T,1}
    P_normal::Array{T,2}
    P_cuarentena::Array{T,2}
    frac_pobla_cuarentena::Array{T,2}
end
