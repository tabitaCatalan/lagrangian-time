#=
Este archivo contiene funciones para modificar los datos del DP50 del MINSAL
https://github.com/MinCiencia/Datos-COVID19/tree/master/output/producto50

El archivo contiene datos de defunciones por comuna.

Incluso es posible leer los datos directamente del URL. Eso podría ser útil.
=#
using CSV
using TimeSeries

"""
    cols_with_no_missing(TS_data::TimeSeries; threshold = 0)
Para una serie de tiempo, devuelve un `Array` con los nombres de las columnas
que no contienen datos `missing`. Opcionalmente es posible fijar un umbral.
# Argumentos
- `TS_data::TimeSeries`
- `threshold = 0`: (opcional) se conservarán las columnas que tenga a lo más
    `threshold` datos `missing`. Por defecto es 0, así que elimina cualquier
    columna que tenga al menos un dato faltante.
"""
function cols_with_no_missing(TS_data::TimeArray; threshold = 0)
    filter(col -> count( ismissing.(values(TS_data[col]))) <= threshold, colnames(TS_data))
end

"""
    colname_to_region_number(col::Symbol)
Recibe un símbolo que contiene el código territorial de una comuna. Entrega un
entero de la región donde está la comuna.
# Argumentos
- `col::Symbol`: recibe un símbolo de la forma `Symbol(string_number)`, donde
    `string_number` es un `String` que puede transformarse en un número. Se
    espera además que el número sea un código único territorial, el cual es de
    la forma: `numero_region * 1000 + numero_provincia * 100 + numero_comuna`.
    Un ejemplo es `Symbol("13501")`, que correspone a la comuna de Melipilla, y
    `Symbol("6301")`, que corresponde a la comuna de San Fernando.
# Ejemplos
```julia-repl
julia> colname_to_region_number(Symbol("13501"))
13
julia> colname_to_region_number(Symbol("6301"))
6
```
"""
function colname_to_region_number(col::Symbol)
    str_col = string(col)
    if occursin("_",str_col)
        0
    else
        floor(Int, parse(Float64, str_col)/1000)
    end
end

"""
    indexs_RM(col_names::Vector{Symbol})
Recibe un listado de `Symbols` de códigos territoriales comunales. Devuelve un
arreglo de `Bit`s del mismo largo, con `1`s en las posiciones de las columnas de
de la región metropolitana.
# Ejemplos
Hacemos un listado con las comunas de Melipilla (código territorial 13501) y
San Fernando (código 6301).
```julia-repl
julia> indexs_RM([Symbol("13501"), Symbol("6301")])
2-element BitArray{1}:
 1
 0
```
"""
indexs_RM(col_names::Vector{Symbol}) = colname_to_region_number.(col_names) .== 13

"""
    es_cama_ocupada(col_name::Symbol, str_final::String)
Recibe un `Symbol` y devuelve `true` si el string asociado al `Symbol` termina
el `str_final`.
"""
function termina_en(col_name::Symbol, str_final::String)
    str_name = string(col_name)
    if length(str_name) < length(str_final)
        false
    else
        str_name[end-length(str_final)+1:end] == str_final
    end
end

"""
    es_SS_METRO(col_name::Symbol)
Recibe un `Symbol` y devuelve `true` si el string asociado comienza con
`"SS METROPOLITANO"`.
"""
es_SS_METRO(col_name::Symbol) = string(col_name)[1:16] == "SS METROPOLITANO"

"""
    es_vmi_c19_confi(col_name::Symbol)
Recibe un `Symbol` y devuelve `true` si el string asociado termina en
`"Vmi covid19 confirmados"`.
"""
es_vmi_c19_confi(col_name::Symbol) = termina_en(col_name, "Vmi covid19 confirmados")

"""
    es_vmi_c19_sosp(col_name::Symbol)
Recibe un `Symbol` y devuelve `true` si el string asociado termina en
`"Vmi covid19 sospechosos"`.
"""
es_vmi_c19_sosp(col_name::Symbol) = termina_en(col_name, "Vmi covid19 sospechosos")



"""
    cols_camas_ocupadas_RM(TS_data::TimeArray)
Recibe una serie de tiempo y devuelve un serie que solo tiene las columnas
asociadas a las camas UCI ocupadas de la Región Metropolitana.
"""
function cols_c19_RM(TS_data::TimeArray)
    filter(col -> es_SS_METRO(col) & (es_vmi_c19_sosp(col) | es_vmi_c19_confi(col)), colnames(TS_data))
end

function condensar_por_edad_sexo(TS_GE::TimeArray, TS_rep::TimeArray)
    #cumTS_rep = cumsum(TS_rep, dims = 1)
    #frac_rep_RM_del_total = (cumTS_rep[Symbol("Metropolitana")] ./ cumTS_rep[Symbol("Total")])[2:end]

    #t0 = max(timestamp(TS_GE)[1], timestamp(frac_rep_RM_del_total)[1])
    #tf = min(timestamp(TS_GE)[end], timestamp(frac_rep_RM_del_total)[end])

    #tiempos_validos = timestamp(TS_GE[t0:Dates.Day(1):tf])

    TS_GE_corta = TS_GE #[tiempos_validos]
    #TS_frac_corta = frac_rep_RM_del_total[tiempos_validos]

    joven = 1:5; adulto = 6:13; mayor = 14:17
    hombre = 0; mujer = 1

    get_index(edad,sexo) = sexo*17 .+ edad

    col_names = colnames(TS_GE_corta)
    Nt = length(timestamp(TS_GE_corta))
    condensed = Array{Int64, 2}(undef, Nt, 6)
    Str_edad = ["Joven", "Adulto", "Mayor"]
    Str_sexo = ["M", "F"]
    col_names_condensed = Vector{String}(undef, 6)
    edades = (joven, adulto, mayor)
    sexos =  (hombre, mujer)
    for i in 1:3, j in 1:2
        clase = 2*(i-1) + j
        condensed[:,clase] =  sum(values(TS_GE_corta[col_names[get_index(edades[i], sexos[j])]]), dims = 2)
        println("Edad: ", edades[i], ", Sexo:", sexos[j])
        col_names_condensed[clase] = Str_sexo[j] * Str_edad[i]
    end

    #condensed_reescaled = condensed .* values(TS_frac_corta)

    TS_condensed = TimeArray(timestamp(TS_GE), condensed, Symbol.(col_names_condensed))

    TS_condensed
end

function parse_semana_epi(str_semana)
    # str_number de la forma "SE1", "SE15"
    numero_semana = parse(Int, str_semana[3:end])
    dia_SE1 = Date(2020,01,04)
    dia_SE = dia_SE1 + Dates.Day((numero_semana - 1)*7)
    dia_SE
end


minsal_folder = "C:\\Users\\Tabita\\Documents\\Covid\\Datos-COVID19-MINSAL\\output\\"
DEIS_data = "producto50\\DefuncionesDEIS_confirmadosPorComuna_T.csv"
reportados_data = "producto26\\CasosNuevosConSintomas_T.csv"
UCI_data_SS = "producto48\\SOCHIMI_T.csv"
UCI_data = "producto8\\UCI_T.csv"
GE_data = "producto16\\CasosGeneroEtario_T.csv"
rep_por_comuna_data = "producto15\\FechaInicioSintomas_T.csv"



TS_nuevos_comuna = TimeArray(CSV.File(minsal_folder * rep_por_comuna_data, header = 4, datarow = 6), timestamp = Symbol("Codigo comuna"), timeparser = parse_semana_epi)

TS_nuevos_comuna_RM = TS_nuevos_comuna[colnames(TS_nuevos_comuna)[colname_to_region_number.(colnames(TS_nuevos_comuna)) .== 13]]

TS_UCI = TimeArray(CSV.File( minsal_folder * UCI_data, header = 2, datarow = 4),
    timestamp = Symbol("Codigo region"))

TS_UCI_RM = TS_UCI[Symbol("13")]
timestamp(TS_UCI_RM)[end]

TS_DEIS = TimeArray(CSV.File(minsal_folder * DEIS_data,
        header = 4, datarow = 6,
        typemap = Dict(Float64=>Int64)
    ), timestamp = Symbol("Codigo comuna")
)
full_cols = cols_with_no_missing(TS_DEIS)
TS_DEIS_RM = TS_DEIS[full_cols[indexs_RM(full_cols)]]

TS_reportados = TimeArray(
    CSV.File(minsal_folder * reportados_data),
    timestamp = Symbol("Region")
)
TS_reportados_RM = TS_reportados.Metropolitana

TS_GE = TimeArray(CSV.File( minsal_folder * GE_data,
    header = 1:2, datarow = 3),
    timestamp = Symbol("Grupo de edad_Sexo")
)
TS_edad_sexo = condensar_por_edad_sexo(TS_GE, TS_reportados)

plot(TS_edad_sexo, title = "Casos por género y grupo etario")




TS_UCI_SS = TimeArray(
    CSV.File(minsal_folder * UCI_data_SS,
        header = 3:4, datarow = 5
    ), timestamp = Symbol("Servicio salud_Serie")
)

TS_UCI_SS_RM = TS_UCI_SS[cols_c19_RM(TS_UCI_SS)];
#=
TS_UCI_Vis = TimeArray(
    CSV.File( "..\\..\\data\\PacientesCovid-19UCIanivel_Visualizador.csv",
        transpose=true,
    ), timestamp = Symbol("nombre")
)
plot(TS_nuevos_comuna_RM)


es_tramo(col, tramo)
TS_nuevos_comuna_RM
1e5
comunas
indexin(13502, comunas.id_comuna)
find_index_comuna = cod -> findfirst(comunas.id_comuna .== cod)
tramos = comunas.tramo_pobreza[find_index_comuna.(parse.(Int, string.(colnames(TS_nuevos_comuna_RM))))]
pobla = [sum(comunas.poblacion_total[comunas.tramo_pobreza .== i]) for i in 1:3]
plot(title = "Incidencia real por nivel socioeconómico")
plot!(cumsum(sum(TS_nuevos_comuna_RM[colnames(TS_nuevos_comuna_RM)[tramos .== 1]], dims = 2), dims = 1)[4:end] .* (1e5/pobla[1]), label = "Nvl Bajo")
plot!(cumsum(sum(TS_nuevos_comuna_RM[colnames(TS_nuevos_comuna_RM)[tramos .== 2]], dims = 2), dims = 1)[4:end] .* (1e5/pobla[2]), label = "Nvl Medio")
plot!(cumsum(sum(TS_nuevos_comuna_RM[colnames(TS_nuevos_comuna_RM)[tramos .== 3]], dims = 2), dims = 1)[4:end] .* (1e5/pobla[3]), label = "Nvl Alto")
ylabel!("Casos por 100.000 habitantes")

savefig(output_folder * "incid_nvlsocio_real" * extension)

plot(frac_outbreak)
plot(TS_reportados.Total)
plot!(TS_reportados.Metropolitana)
plot(TS_edad_sexo, yscale = :log10)


plot(title = "Incidencia real por grupo etario")
plot!(1e5 .* sum(TS_edad_sexo[[:MJoven, :FJoven]], dims = 2)./ sum(pobla_nacional[1:2]), label = "Joven")
plot!(1e5 .* sum(TS_edad_sexo[[:MAdulto, :FAdulto]], dims = 2)./ sum(pobla_nacional[3:4]), label = "Adulto")
plot!(1e5 .* sum(TS_edad_sexo[[:MMayor, :FMayor]], dims = 2)./ sum(pobla_nacional[5:6]), label = "Mayor")
ylabel!("Casos por 100.000 habitantes")
savefig(output_folder * "incid_edad_real" * extension)


plot(values(sum(TS_edad_sexo[[:MJoven, :FJoven]], dims = 2))./ sum(data_u0.total_por_clase[joven]), label = "Joven")
=# 
