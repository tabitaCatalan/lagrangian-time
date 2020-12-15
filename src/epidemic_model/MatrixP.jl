#=
Este archivo modifica la matriz P obtenida con Matlab, para usarla por el modelo
=#
using MAT


"""
    read_matlab_data(mat_filename)
Leer datos obtenidos con Matlab.
# Argumentos
- `mat_filename::String`: nombre del archivo que contiene los datos generados
    por Matlab para trabajar con `n` clases y `m` ambientes. Debe incluir la
    extension `.mat`. Se espera que contenga cuatro variables:
    - `P`: matriz de tiempos de residencia, de `n` filas y `m` columnas.
        `P[i,j]` indica la fraccion de tiempo que la clase `i` pasa en el ambiente
        `j`. No necesariamente debe sumar 1 por fila (se normalizará después).
    - `total_por_clase`: vector de largo `n`, cantidad de individuos por clase.
    - `ambientes`: vector de largo `m`, nombre corto de los ambientes.
    - `nombres_clases`:  vector de largo `n`, nombre corto de las clases.
# Ejemplos
```julia
P, total_por_clase, nombre_ambientes, nombre_clases = read_matlab_data("..\\results\\Pdata.mat")
```
"""
function read_matlab_data(mat_filename)
    Pdata = matopen(mat_filename)
    names(Pdata)
    P = read(Pdata, "P")
    total_por_clase = vec(read(Pdata, "total_por_clase"))
    nombre_ambientes = read(Pdata, "ambientes")
    nombre_clases = read(Pdata, "nombres_clases")
    close(Pdata)
    return P, total_por_clase, nombre_ambientes, nombre_clases
end

"""
    suma_uno_por_fila!(P)
Reescala los valores de P, para que sume 1 por fila.
# Ejemplos
```jldoctest
julia> suma_uno_por_fila!([0.2 0.5 0.1; 0.1 0.3 0.4])
2×3 Array{Float64,2}:
 0.25   0.625  0.125
 0.125  0.375  0.5
```
"""
function suma_uno_por_fila!(P)
    P ./= sum(P, dims = 2)
end

"""
    aplicar_cuarentena!(P)
Modifica la matriz `P`, reduciendo el tiempo invertido en los ambientes trabajo,
estudios y transporte, y lo traspasa al hogar.
El tiempo en el estudio se reduce en un 95% (no en un 100% para evitar que haya
inestabilidad al resolver la EDO).
El tiempo en el trabajo se reduce en un 20% para clase baja, 50% para clase media
y en un 80% para clase alta.
El tiempo en todos los medios de transporte se reduce en un 50%.
# Argumentos
- `P`: matriz de tiempos de residencia de clases vs ambientes.
## Supuestos
Hay 18 clases:\n
**Indice** | **Clase** \n
1      | Hombre clase baja joven \n
2      | Mujer clase baja joven \n
3      | Hombre clase media joven \n
4      | Mujer clase media joven \n
5      | Hombre clase alta joven \n
6      | Mujer clase alta joven \n
7      | Hombre clase baja adulto \n
8      | Mujer clase baja adulto \n
9      | Hombre clase media adulto \n
10     | Mujer clase media adulto \n
11     | Hombre clase alta adulto \n
12     | Mujer clase alta adulto \n
13     | Hombre clase baja mayor \n
14     | Mujer clase baja mayor \n
15     | Hombre clase media mayor \n
16     | Mujer clase media mayor \n
17     | Hombre clase alta mayor \n
18     | Mujer clase alta mayor \n

Hay 13 ambientes: \n
**Indice** | **Ambiente** \n
1      | Hogar \n
2      | Trabajo \n
3      | Estudios \n
4      | Compras \n
5      | Visitas \n
6      | Salud \n
7      | Tramites \n
8      | Recreo \n
9      | Transporte publico \n
10     | Auto \n
11     | Caminata \n
12     | Bicicleta \n
13     | Otro
# Detalles de la implementación
Se mantiene constante la proporción entre el tiempo gastado en el transporte
y el tiempo fuera del hogar. Esta proporción se llama δ y se calcula para cada clase.
"""
function aplicar_cuarentena!(P)
    δ = calcular_delta(P)

    reducir_tiempo_estudios!(P)

    trabajo = 2; recreacion = 8; visitas = 5; compras = 4
    reducir_tiempo_ambiente_por_clase!(P, trabajo, (0.2, 0.4, 0.6))
    #reducir_tiempo_ambiente_por_clase!(P, recreacion, (0.3, 0.6, 0.9))
    reducir_tiempo_ambiente_por_clase!(P, visitas, (0.0, 0.0, 0.0))
    reducir_tpo_en_ambiente!(P, recreacion, 75)
    #reducir_tpo_en_ambiente!(P, visitas, 95)
    reducir_tiempo_ambiente_por_clase!(P, compras, (0.0, 0.0, 0.0))


    corregir_tiempo_transporte!(P, δ)
end

function cerrar_colegios!(P, δ)
    reducir_tiempo_estudios!(P)
    corregir_tiempo_transporte!(P, δ)
end

function teletrabajo!(P, δ)
    reducir_tiempo_trabajo!(P)
    corregir_tiempo_transporte!(P, δ)
end

"""
    calcular_delta(P)
Calcula la relación entre el tiempo gastado en el transporte  y el tiempo en los
lugares fuera del hogar (que no incluyan transporte), para cada clase.
# Argumentos
- `P`: Array de dim = 2
    Matriz de movilidad
"""
function calcular_delta(P)
    hogar = 1:1
    transporte = index_transporte()
    lugares_fuera_del_hogar = [collect(2:8); 13]
    δ = sum(P[:,transporte], dims = 2)./sum(P[:,lugares_fuera_del_hogar], dims = 2)
    δ
end

function index_transporte()
    9:12
end


"""
    corregir_tiempo_transporte!(P, δ)
Suponemos que el tiempo en los ambientes fuera del hogar (sin incluir transporte)
se han reducido. Se reducirá el tiempo en el transporte, procurando mantenar la
proporción de estos tiempos constante (δ, calcudala previamente)
# Argumentos
- `P`:
- `δ`:
# Metodología
"""
function corregir_tiempo_transporte!(P, δ)
    hogar = 1:1
    transporte = index_transporte()
    lugares_fuera_del_hogar = [collect(2:8); 13]
    tiempo_transporte_antiguo = sum(P[:,transporte], dims = 2)
    tiempo_fuera_hogar_nuevo = sum(P[:,lugares_fuera_del_hogar], dims = 2)
    tiempo_transporte_nuevo = δ.*tiempo_fuera_hogar_nuevo
    P[:, transporte] = P[:, transporte] .* tiempo_transporte_nuevo ./tiempo_transporte_antiguo
    P[:, hogar] += tiempo_transporte_antiguo - tiempo_transporte_nuevo
    P
end

"""
    reducir_tiempo_trabajo!(P)
Modifica una matriz de tiempos de residencia, disminuyendo el tiempo en el
trabajo ha en un 20% para la clase baja, un 50% para la clase media y un 80%
para la clase alta (y agregándolo al hogar).
# Argumentos
- `P`: array de dim 2
    Matriz de tiempos de residencia.
"""
function reducir_tiempo_ambiente_por_clase!(P, ambiente, fraccion_por_clase)
    hogar = 1
    tpo_ambiente = P[:,ambiente]
    clase_baja, clase_media, clase_alta = index_clases()
    frac_reduccion = ones(18)
    frac_reduccion[clase_baja] .= fraccion_por_clase[1]
    frac_reduccion[clase_media] .= fraccion_por_clase[2]
    frac_reduccion[clase_alta] .= fraccion_por_clase[3]
    P[:,hogar] += tpo_ambiente.*frac_reduccion
    P[:,ambiente] -= tpo_ambiente.*frac_reduccion
end


"""
    reducir_tpo_en_ambiente!(P, ambiente, p100_reduccion)
Modifica la matriz P, reduciendo el tiempo gastado en un ambiente para todas
las clases en un porcentaje. Agrega ese tiempo al hogar.
- `P`: matriz de tiempos de residencia.
- `ambiente::Int`: numero de columna de la matriz al que se le reducirá el tpo.
- `p100_reduccion`: porcentaje de reduccion (entre 0 y 100).
"""
function reducir_tpo_en_ambiente!(P, ambiente, p100_reduccion)
    hogar = 1
    P[:,hogar] += (p100_reduccion/100)*P[:,ambiente]
    P[:,ambiente] *= (100 - p100_reduccion)/100
end

"""
    reducir_tiempo_estudios!(P)
Modifica una matriz de tiempos de residencia, disminuyendo el tiempo en el ambiente
estudios en un 95% (y agregándolo al hogar).
# Argumentos
- `P`: array de dim 2
Matriz de tiempos de residencia.
"""
function reducir_tiempo_estudios!(P)
    estudios = 3
    reducir_tpo_en_ambiente!(P, estudios, 95)
end

"""
    reducir_tiempo_transporte!(P)
Modifica una matriz de tiempos de residencia, disminuyendo el tiempo en todos
los ambientes asociados a transporte a la mitad (y agregándolo al hogar).
# Argumentos
- `P`: array de dim 2
Matriz de tiempos de residencia.
"""
function reducir_tiempo_transporte!(P)
    medios_de_transporte = index_transporte()
    for transporte in medios_de_transporte
        reducir_tpo_en_ambiente!(P, transporte, 50)
    end
end

v_p100s = Dict{Int,Vector{Float64}}(1 => [0.1,0.5,0.8], 5=> [-0.1,0.4,0.6])



"""
    variation_p100!(P,v_p100s)
# Argumentos
- `P`: matriz de tiempos de residencia. Será modificada.
- `v_p100s::Dict{Int, Array{Number}}`: diccinario donde `key => value` quiere decir
    que `value` contiene un array de largo 3, de tal forma que `value[i]` corresponde
    a la variacion de la cantidad en la columna `key`-ésima, en todos las filas
    asociadas a la clase baja (`i=1`), clase media (`i=2`) o clase alta (`i=3`).
"""
function variation_p100!(P,v_p100s)
    for (ambiente, variaciones_por_clase) in v_p100s
        for clase in 1:3
            filas_clase = map_class_index(clase)
            P[filas_clase,ambiente] += variaciones_por_clase[i] .* P[filas_clase,ambiente]
        end
    end
end

function map_class_index(i)
    if i == 1
        index = clase_baja()
    elseif i == 2
        index = clase_media()
    elseif i == 3
        index = clase_alta()
    else
        index = []
    end
    index
end
