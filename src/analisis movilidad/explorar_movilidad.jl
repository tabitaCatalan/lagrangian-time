using Base: first_index
using TimeSeries: findall, minimum, maximum
using CSV 
using TimeSeries
using DataFrames
using Query
using Statistics

minsal_data_dir = "C:\\Users\\Tabita\\Documents\\Covid\\Datos-COVID19-MINSAL\\output\\"
producto = "producto33\\IndiceDeMovilidad.csv" 

IMData = DataFrame(CSV.File(minsal_data_dir * producto))
IMDataSntg = filter(row -> !ismissing(row.Region) && row.Region == "Metropolitana de Santiago", IMData) 

# Voy a usar a Sn Bdo para sacar las fechas 


SnBdoData = DataFrame(filter(row -> !ismissing(row.Comuna) && row.Comuna == "San Bernardo", IMData))
LasCondesData = DataFrame(filter(row -> !ismissing(row.Comuna) && row.Comuna == "Las Condes", IMData))

SntgCodigosComunas = unique(IMDataSntg[!,"Codigo comuna"])
SntgIM_TS = TimeArray(SnBdoData.Fecha, reshape(Vector{Float64}(select(IMDataSntg, :IM).IM), (279,52)), Symbol.(SntgCodigosComunas))
SntgIM_in_TS = TimeArray(SnBdoData.Fecha, reshape(Vector{Float64}(select(IMDataSntg, :IM_interno).IM_interno), (279,52)), Symbol.(SntgCodigosComunas))
SntgIM_ex_TS = TimeArray(SnBdoData.Fecha, reshape(Vector{Float64}(select(IMDataSntg, :IM_externo).IM_externo), (279,52)), Symbol.(SntgCodigosComunas))


# Graficamos la info para todas las comunas, hay mucha oscilación 
plot(SntgIM_TS)
# Media movil de 7 días, funciona muy bien
# probablemente porque la oscilación es semanal 
plot(moving(mean, SntgIM_TS, 7))

# Agregar info socioeconómica 

project_dir = "C:\\Users\\Tabita\\Documents\\Covid\\GitHub\\"

eod_db = "\\data\\EOD2012-Santiago.db" 
sql_query_pobreza = "\\src\\time_residence_matrix\\query-tramopobreza-comunas.sql"

include("src\\ReadDataUtils.jl") 
tramos_por_comuna = read_db(project_dir * eod_db, project_dir * sql_query_pobreza) 

tramos_por_comuna = read_db(project_dir * eod_db, project_dir * sql_query_pobreza) 

DB_EOD =  SQLite.DB(project_dir * eod_db)

# Leer consulta SQL del archivo y guardar como String

sql_tramos = "SELECT * FROM TasaPobreza"
sql_comunas = "SELECT * FROM ComunasSantiago"
results_df = DataFrame(DBInterface.execute(DB_EOD, sql_tramos))
comunas_df = DataFrame(DBInterface.execute(DB_EOD, sql_comunas)) 

result_df[2,2]

function find_by_code_symbol(code_symbol, df)
    code = parse(Int, String(code_symbol)) 
    first_index_code = findall(x -> x == code, df[!,1])[1]
    df[first_index_code, 2]
end

pobreza_indexs = [find_by_code_symbol(colnames(SntgIM_TS)[i], results_df) for i = 1:52]
names_comunas = [find_by_code_symbol(colnames(SntgIM_TS)[i], comunas_df) for i=1:52]


function normalize(vector, minv, maxv)
    (vector .- minv)./ (maxv - minv)
end 

function normalize(vector)
    minv = minimum(vector)
    maxv = maximum(vector) 
    normalize(vector, minv, maxv)
end 

normalized_pobreza = normalize(pobreza_indexs) # para dejarlo en [0,1]

plot(moving(mean, SntgIM_TS, 7), color = cg[normalized_pobreza]', legend=:none, title = "IM")
plot(moving(mean, SntgIM_in_TS, 7), color = cg[normalized_pobreza]', legend=:none, title = "IM interno")
plot(moving(mean, SntgIM_ex_TS, 7), color = cg[normalized_pobreza]', legend=:none, title = "IM externo")
plot(LasCondesData.IM, color = :blue)



#comunas_altas = Symbol.([13111, 13129, 13123, 13113, 13102, 13504, 13303])
comunas_altas = Symbol.([13111, 13504])
plot(moving(mean, SntgIM_ex_TS, 7),
    marker_z = normalized_pobreza',
    color = :flag_ml, # esto no funciona como esperaba... además hay que revertir
    label = :none,
    title = "IM externo",
    alpha = 0.3
)
nombres_comunas_altas = map(code -> find_by_code_symbol(code, comunas_df), comunas_altas)
indices_comunas_altas = map(code -> find_by_code_symbol(code, results_df), comunas_altas)
plot(moving(mean, SntgIM_ex_TS, 7)[comunas_altas],
    label = reshape(nombres_comunas_altas, (1,length(comunas_altas))),
    palette = cgrad(:flag_ml, rev = true),
    #cgrad = cgrad(:flag_ml, rev = true),
    marker_z = normalize(indices_comunas_altas, minimum(pobreza_indexs), maximum(pobreza_indexs))', 
    legend = :bottomright
)
vline!([Date(2020,3,15)], color = :blue, label = "15/03/2020")

#=
Cálculo de IM Base, para expresar los demás como variación c/r a ese 
=# 

SntgIM_base = mean(SntgIM_TS[5:18], dims = 1) 
SntgIM_base = mean(SntgIM_TS[[6:10;13:17]], dims = 1) 


plot(100 .* (SntgIM_TS ./ SntgIM_base .- 1))

plot(100 .* (moving(mean, SntgIM_TS, 7) ./ values(SntgIM_base) .- 1.), label = :none)

# Datos ISCI 
producto51 = "producto51\\ISCI_std.csv" 


MovData = DataFrame(CSV.File(minsal_data_dir * producto51))
SntgMivData = filter(row -> !ismissing(row.Region) && row["Codigo region"] == 13, MovData) 
#IMDataSntg = filter(row -> !ismissing(row.Region) && row.Region == "Metropolitana de Santiago", IMData)  

parse_fecha(str) = Date(str[1:10])
 
"""
    parse_string_dif(str::String)
parsea un String de diferencia a una tupla 
# Example 
```julia-repl
julia> parse_string_dif("[-100%, +20%]")
(-100, 20)
```
"""
function parse_string_dif(str::String) 
    index_comma = findfirst(isequal(','), str) 
    first_number = str[2:index_comma-2]
    second_number = str[index_comma+1:end-3] 
    parse(Int, first_number), parse(Int, second_number)
end

DifSalida = parse_string_dif.(MovData[!,"Dif salida"])
DifEntrada = parse_string_dif.(MovData[!,"Dif entrada"])

# Me falta una forma de agrupar todas las
# zonas censales para obtener resultados por comuna   
# Intentaría agrupar, suponer independencia y propagar así la 
# covarianza  

means = map(x -> (x[1] + x[2])/2, DifSalida) 
vars = map(x -> (x[2]-x[1])^2, DifSalida) 

A = ones(5) ./ 5 
means[1:5] 


function diag_vector(M)
    n,m = size(M) 
    print(n == m) 
    [M[i,i] for i = 1:n]

end

sqrt(A' * (A .* vars[1:5])) 

mean
using LinearAlgebra


