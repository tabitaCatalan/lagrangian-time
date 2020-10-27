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

cd(@__DIR__) # me deja en GitHub
cd("src\\epidemic_model")

# Quiero una función que modifique la matriz P ... dependiendo de....
# Array{3} (Ponderadores de las 3 clases) → ponderacion entre matriz P normal y P cuarentena


# Necesito algo que dado el tiempo me dé la ponderacion
# Eso va a requerir que lea la base de datos...

# O que tenga un array con eso guardado
data_cuarentenas = readtimearray("..\\..\\data\\CuarentenasRM.csv";delim = ';')
numero_dias = length(timestamp(data_cuarentenas))

# para cada día necesito una ponderación...
# La ponderacion depende de la poblacion de la comuna...
#pobla_comunas .* cuarentena_comunas = poblacion_en_cuarentena 

DB_EOD = SQLite.DB("..\\..\\data\\EOD2012-Santiago.db")


io = open("query-poblacion-clase.sql", "r")
sql = read(io, String)
close(io)

tramos = DBInterface.execute(DB_EOD, sql)
tramos_df = DataFrame(tramos)
tramo_pobreza = tramos_df.tramo_pobreza # tramos por comuna
pobla_por_comuna = tramos_df.poblacion_total


function calcular_pobla_en_cuarentena(tiempo)
    t_floor = floor(Int, tiempo)
    cuarentenas_en_t = values(data_cuarentenas[t_floor])'
    comunas_sin_cuarentena = [34, 42, 44, 46, 47, 50]
    f = i -> in(i, comunas_sin_cuarentena)
    comunas_con_cuarentena = .!f.(1:52)
    pobla_en_cuarentena = similar(pobla_por_comuna)
    pobla_en_cuarentena[comunas_sin_cuarentena] .= 0
    pobla_en_cuarentena[comunas_con_cuarentena] = pobla_por_comuna[comunas_con_cuarentena] .* cuarentenas_en_t
    pobla_en_cuarentena
end


#=
┌───────────────┬─────────────────┬───────────────────┐
│ tramo_pobreza │ poblacion_total │  frac_poblacion   │
├───────────────┼─────────────────┼───────────────────┤
│ 1             │ 2456390         │ 0.345347435218271 │
│ 2             │ 3071158         │ 0.431778560590979 │
│ 3             │ 1585260         │ 0.22287400419075  │
└───────────────┴─────────────────┴───────────────────┘
=#
pobla_en_cuarentena = calcular_frac_en_cuarentena(100)
frac_t1 = sum(pobla_en_cuarentena[tramo_pobreza .== 1])/2456390
frac_t2 = sum(pobla_en_cuarentena[tramo_pobreza .== 2])/3071158
frac_t3 = sum(pobla_en_cuarentena[tramo_pobreza .== 3])/1585260

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

#=
mutable struct MyDataArray{T,1} <: DEDataArray{T,1}
    x::ComponentArray{T,1}
    P::Array{T,2}
end
=#

frac_t1   frac_t2_v2
----    = ---
1         alpha < 1