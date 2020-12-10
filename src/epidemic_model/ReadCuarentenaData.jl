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
- `csv_cuarentena::String`: path al csv con la serie de tiempo correspondiente a
    la cuarentena por dia y comuna.
# Salida
- `data_cuarentena::TimeSeries`  (fechas en las filas, comunas en las columnas)
- `numero_dias`: cuantos dias están considerados en los datos.
# Ejemplo
```julia
data_cuarentenas, numero_dias = read_data_cuarentena('..\\..\\data\\CuarentenasRM.csv';
    delim = ';'
)
```
"""
function read_data_cuarentena(csv_cuarentena; delim = delim)
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
    procesar_PaP!(cuarentenas_en_t, modo)
Calcula la fraccion de personas en cuarentena.
# Argumentos
- `cuarentenas_en_t`: array donde la posicion (dia, comuna)
    tiene la informacion de qué tipo de cuarentena se realiza.
- `modo`: hay dos opciones
    - `:cuarentena`
        No pasa nada. Suponemos que esta codificado como `0` si no hay cuarentena
        y `1` si sí la hay.
    - `:PaP`
        En el modo plan paso a paso, se espera que la matriz de cuarentena
        tenga la fase del plan en que está la comuna para cada día. Los valores
        válidos están entre 1 y 5. La fase 1 corresponde a cuarentena, se asume
        un 100% de personas cuarentenadas. La fase 2 corresponde a cuarentena los
        fines de semanas, por lo que consideramos 2/7 de personas cuarentenadas
        (solo 2 de 7 días). Desde la fase 3 en adelante consideramos 0% de personas
        cuarentenas, aunque podría buscarse otro enfoque ya que aun hay medidas
        en esas fases.
# Lectura adicional
https://www.minsal.cl/presidente-sebastian-pinera-presenta-plan-paso-a-paso/
"""
function procesar_PaP!(cuarentenas_en_t, modo)
    if modo == :cuarentena
        comunas_sin_cuarentena = cuarentenas_en_t .== 0
        cuarentenas_en_t[comunas_sin_cuarentena] .= 0.25 # diremos que sin había un 25% de cuarentena y un 75% de normalidad

    elseif modo == :PaP

        # El paso 1 es 100% cuarentena, el paso 2 es 90% cuarentena, ... etc.
        p100_cuarentena_paso = (100, 90, 75, 50, 25)

        for i in 1:5
            paso_i = cuarentenas_en_t .== i
            cuarentenas_en_t[paso_i] .= p100_cuarentena_paso[i]/100
        end
    else
        print("Ingrese un modo válido. Las opciones disponibles son :cuarentena y :PaP (paso a paso)")
    end
end


"""
    calcular_pobla_en_cuarentena(tiempo, data_cuarentenas, df)
Calcula la cantidad de personas que están en cuarentena en cierto tiempo.
"""
function calcular_pobla_en_cuarentena_en_t(t_floor, data_cuarentenas, df, modo)
    cuarentenas_en_t = values(data_cuarentenas[t_floor])'
    #comunas_sin_cuarentena = [34, 42, 44, 46, 47, 50]
    #comunas_sin_cuarentena = []
    #f = i -> in(i, comunas_sin_cuarentena)
    #comunas_con_cuarentena = .!f.(1:52)
    comunas_con_cuarentena = 1:52
    pobla_por_comuna = df.poblacion_total
    pobla_en_cuarentena = similar(pobla_por_comuna)
    #pobla_en_cuarentena[comunas_sin_cuarentena] .= 0
    procesar_PaP!(cuarentenas_en_t, modo)
    pobla_en_cuarentena[comunas_con_cuarentena] = floor.(pobla_por_comuna[comunas_con_cuarentena] .* cuarentenas_en_t)
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
function calcular_frac_cuarentena_en_t_por_tramo!(frac, tiempo, data_cuarentenas, df, modo)
    t_floor = floor(Int, tiempo)
    pobla_tramo = (2456390, 3071158, 1585260)
    pobla_en_cuarentena = calcular_pobla_en_cuarentena_en_t(t_floor, data_cuarentenas, df, modo)
    pobla_en_cuarentena = calcular_pobla_en_cuarentena_en_t(t_floor, data_cuarentenas, df, modo)
    frac_t1 = sum(pobla_en_cuarentena[df.tramo_pobreza .== 1])/pobla_tramo[1]
    frac_t2 = sum(pobla_en_cuarentena[df.tramo_pobreza .== 2])/pobla_tramo[2]
    frac_t3 = sum(pobla_en_cuarentena[df.tramo_pobreza .== 3])/pobla_tramo[3]
    frac[t_floor,1] = frac_t1
    frac[t_floor,2] = frac_t2
    frac[t_floor,3] = frac_t3
end

"""
    calcular_frac_cuarentena(data_cuarentenas, df)
Devuelve un array con la cantidad de personas en cuarentena cada día.
"""
function calcular_frac_cuarentena(data_cuarentenas, df, modo)
    numero_dias = contar_dias(data_cuarentenas)
    pobla_en_cuarentena = zeros(numero_dias)
    for dia in 1:numero_dias
        pobla_en_cuarentena[dia] = sum(calcular_pobla_en_cuarentena_en_t(dia, data_cuarentenas, df, modo))
    end
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
function calcular_frac_cuarentena_por_tramo(data_cuarentenas, df, modo)
    numero_dias = contar_dias(data_cuarentenas)
    frac = zeros(numero_dias, 3)
    for i in 1:numero_dias
        calcular_frac_cuarentena_en_t_por_tramo!(frac,i, data_cuarentenas, df, modo)
    end
    frac
end

"""
    obtener_frac_cuarentena_from_csv(csv_cuarentena, eod_db, pobla_query, delim = ';', mode)
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
function obtener_frac_cuarentena_from_csv(csv_cuarentena, eod_db, pobla_query; delim = ',', tramos = true, modo)
    data_cuarentenas, numero_dias = read_data_cuarentena(csv_cuarentena; delim = delim)
    tramos_df = read_db(eod_db, pobla_query)
    if tramos
        frac = calcular_frac_cuarentena_por_tramo(data_cuarentenas, tramos_df, modo)
    else
        frac = calcular_frac_cuarentena(data_cuarentenas, tramos_df, modo)
    end
    frac, timestamp(data_cuarentenas)
end
