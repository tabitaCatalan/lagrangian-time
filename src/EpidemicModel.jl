#=
Este archivo contien el modelo a usar para modelar la epidemia (SEIIᵐR).
Incluye además funciones para leer datos desde MATLAB.
=#

## Importar dependencias
using MAT
using ComponentArrays
using DifferentialEquations

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
    reducir_tiempo_trabajo!(P)
    reducir_tiempo_estudios!(P)
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
    transporte = 9:12
    lugares_fuera_del_hogar = [collect(2:8); 13]
    δ = sum(P[:,transporte], dims = 2)./sum(P[:,lugares_fuera_del_hogar], dims = 2)
    δ
end


"""
    corregir_tiempo_transporte!(P, δ)
Suponemos que el tiempo en los ambientes fuera del hogar (sin incluir transporte)
se han reducido. Se reducirá el tiempo en el transporte, procurando mantenar la
proporción de estos tiempos constante (δ, calcuda previamente)
# Argumentos
- `P`:
- `δ`:
# Metodología
"""
function corregir_tiempo_transporte!(P, δ)
    hogar = 1:1
    transporte = 9:12
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
function reducir_tiempo_trabajo!(P)
    hogar = 1
    trabajo = 2
    tpo_trabajo = P[:,trabajo]
    clase_baja, clase_media, clase_alta = index_clases()
    frac_reduccion = ones(18)
    frac_reduccion[clase_baja] .= 0.2
    frac_reduccion[clase_media] .= 0.5
    frac_reduccion[clase_alta] .= 0.8
    P[:,hogar] += tpo_trabajo.*frac_reduccion
    P[:,trabajo] -= tpo_trabajo.*frac_reduccion
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
    hogar = 1
    estudios = 3
    P[:,hogar] += 0.95*P[:,estudios]
    P[:,estudios] *= 0.05
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
    transporte = 9:12
    P[:,1] += sum(P[:, transporte], dims = 2)/2.
    P[:, transporte] /= 2.0
end

"""
    index_clases()
# Devuelve los indices asociados a las distintas clases socioeconómicas en la matriz `P`.
# Resultados
- `clase_baja::Array`
- `clase_media::Array`
- `clase_alta::Array`
# Ejemplo
```julia
clase_baja, clase_media, clase_alta = index_clases()
```
"""
function index_clases()
    clase_baja = [1,2,7,8,13,14]
    clase_media = clase_baja .+ 2
    clase_alta = clase_media .+ 2
    return clase_baja, clase_media, clase_alta
end


"""
    index_sexo()
Devuelve los indices asociados a los sexos en la matriz P.
# Resultados
- `masculino`
- `femenino`
"""
function index_sexo()
    masculino = 1:2:17
    femenino = 2:2:18
    return masculino, femenino
end

"""
    index_edad()
Devuelve los indices asociados a los distintos grupos de edad en la matriz P.
# Resultados
- `joven`
- `adulto`
- `mayor`
"""
function index_edad()
    joven = 1:6
    adulto = 7:12
    mayor = 13:18
    return joven, adulto, mayor
end


"""
    seiir!(du,u,p,t)
Modelo epidemiológico tipo SEIIR
# Arguments
- `du`:
- `u`:
- `p`: tupla que contiene los sgtes parámetros
  - `β`: vector de riesgos por ambiente
  - `ν`: vector, tiene que ver con el tiempo de incubacion...
  - `φ`: fraccion de asintomaticos
  - `γ`: tasa de recuperacion asintomaticos
  - `γₘ`: tasa de recuperacion sintomaticos
  - `η`: tasa de muerte
- `t`:
"""
function seiir!(du,u::ComponentArray,p,t)
    α₁,α₂, β, ν, φ, γ, γₘ, P = p
    PᵗᵢI = zeros(size(P_normal)[2])
    PᵗᵢI[1] = sum(u.I)
    λ = P*(( PᵗᵢI + P'*(α₁*u.E + α₂*u.Im)).*β./(P'*(u.S + u.E + u.Im + u.I + u.R)))
    du.S  = -λ.*u.S
    du.E  = λ.*u.S - ν.*u.E
    du.I  = φ*ν.*u.E - γ.*u.I
    du.Im = (1.0 - φ).*ν.*u.E - γₘ .*u.Im
    du.R  = γₘ .*u.Im + γ.*u.I
end;


function seiir_Pt!(du,u::ComponentArray,p,t)
    α₁,α₂, β, ν, φ, γ, γₘ, τ, P1, P2 = p

    PᵗᵢI = zeros(size(P1)[2])
    PᵗᵢI[1] = sum(u.I)
    P = ((P2-P1)/π)*atan(15*(t-τ)) + (P1+P2)/2
    λ = P*(( PᵗᵢI + P'*(α₁*u.E + α₂*u.Im)).*β./(P'*(u.S + u.E + u.Im + u.I + u.R)))
    du.S  = -λ.*u.S
    du.E  = λ.*u.S - ν.*u.E
    du.I  = φ*ν.*u.E - γ.*u.I
    du.Im = (1.0 - φ).*ν.*u.E - γₘ .*u.Im
    du.R  = γₘ .*u.Im + γ.*u.I
end
"""
    set_up_inicial_conditions(total_por_clase)
Crea un vector por componentes con las condiciones iniciales.
# Argumentos
- `total_por_clase::Array`: Vector con la cantidad de personas en cada clase.
"""
function set_up_inicial_conditions(total_por_clase)
    n_clases = length(total_por_clase)
    e0 = 7.0*ones(n_clases)
    i0 = 10*ones(n_clases)
    im0 = 100*ones(n_clases)
    s0 = total_por_clase - e0
    r0 = zeros(n_clases)

    u0 = ComponentArray(S = s0, E = e0, Im = im0, I = i0, R = r0)
    return u0
end

"""
    set_up_parameters(a, beta, gi, gm, phi, nu)
Parametros para una versión simplificada del modelo, donde todas las clases
usan los mismos parámetros.
# Ejemplos
Algunos valores de prueba
a = 0.5
beta = 1.5
gi = 0.55
gm = 0.55
phi = 0.4 en [0,1]
nu = 0.14
"""
function set_up_parameters(a₁,a₂, beta, nu, phi, gi, gm, P)
    β = beta*[0.1, 0.5, 0.7, 0.7, 0.5, 0.5, 0.7, 0.7, 1.0, 0.1, 0.4, 0.1, 0.1]
    ν = nu*ones(n_clases)
    φ = phi
    γ = gi*ones(n_clases)
    γₘ = gm*ones(n_clases)
    p = (a₁,a₂, β, ν, φ, γ, γₘ, P)
    return p
end

function set_up_parameters2(a₁,a₂, beta, nu, phi, gi, gm, τ, P, P2)
    β = beta*[0.1, 0.5, 0.7, 0.7, 0.5, 0.5, 0.7, 0.7, 1.0, 0.1, 0.4, 0.1, 0.1]
    ν = nu*ones(n_clases)
    φ = phi
    γ = gi*ones(n_clases)
    γₘ = gm*ones(n_clases)
    p = (a₁,a₂, β, ν, φ, γ, γₘ, τ, P,P2)
    return p
end

"""
    make_filename(a, beta, nu, phi, gi, gm)
Devuelve un String que puede usarse para nombrar archivos, y que incluye
los parametros usados. La notación es:
`_` + nombre del parámetro + valor del parámetro
Para evitar problemas, se usa `-` como separador decimal.
"""
function make_filename(a₁,a₂, beta, nu, phi, gi, gm)
    filename = "_a1$a₁ _a2$a₂ _beta$beta _nu$nu _phiei$phi _gi$gi _gm$gm"
    filename = replace(filename, " " => "")
    filename = replace(filename, "." => "-")
    println(filename)
    return filename
end
