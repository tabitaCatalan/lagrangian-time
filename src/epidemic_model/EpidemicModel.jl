#=
Este archivo contiene el modelo a usar para modelar la epidemia (SEIIᵐR).
Incluye además funciones para leer datos desde MATLAB.
=#

## Importar dependencias
using ComponentArrays
using DifferentialEquations

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
    αₑ, αᵢₘ, β, ν, φ, γ, γₘ = p
    λ = Array{Float64, 1}(undef, size(u.P_normal)[1])
    P = similar(u.P_normal)
    matrix_ponderation!(P, u.P_normal, u.P_cuarentena, u.frac_pobla_cuarentena[floor(Int,t), :])
    calcular_lambda!(λ, αₑ, αᵢₘ, β, P, u.S, u.E, u.I, u.Im, u.R)
    du.S  = -λ .* u.S
    du.E  = λ .* u.S - ν * u.E
    du.I  = φ * ν * u.E - γ * u.I
    du.Im = (1.0 - φ) * ν * u.E - γₘ * u.Im
    du.R  = γₘ * u.Im + γ * u.I
end;

function calcular_lambda!(λ, αₑ, αᵢₘ, β, P, S, E, I, Iᵐ, R)
    hogar = 1
    N = S + E + I + Iᵐ + R
    λ .= P*(β .* ( αₑ*(P' * E)./(P' * N) + αᵢₘ*(P' * Iᵐ)./(P' * N) ))
    λ .+= (β[1]*(sum(I)/sum(N))) .* P[:,hogar]
end

"""
Permite pasar de una matriz P1 a una matriz P2 en tiempo τ de forma suave.
"""
function seiir_Pt!(du,u::ComponentArray,p,t)
    α₁,α₂, β, ν, φ, γ, γₘ, τ, P1, P2 = p

    PᵗᵢI = zeros(size(P1)[2])
    PᵗᵢI[1] = sum(u.I)
    P = ((P2-P1)/π)*atan((t-τ)) + (P1+P2)/2
    λ = Array{Float64, 1}(undef, size(P_normal)[1])
    calcular_lambda!(λ, α₁, α₂, β, P, u.S, u.E, u.I, u.Im, u.R)
    du.S  = -λ.*u.S
    du.E  = λ.*u.S - ν.*u.E
    du.I  = φ*ν.*u.E - γ.*u.I
    du.Im = (1.0 - φ).*ν.*u.E - γₘ .*u.Im
    du.R  = γₘ .*u.Im + γ.*u.I
end

function seiir_beta_t!(du,u::ComponentArray,p,t)
    α₁,α₂, β₁, β₂, ν, φ, γ, γₘ, τ, P = p
    PᵗᵢI = zeros(size(P)[2])
    PᵗᵢI[1] = sum(u.I)
    β = ((β₂-β₁)/π)*atan((t-τ)) + (β₁+β₂)/2
    λ = Array{Float64, 1}(undef, size(P_normal)[1])
    calcular_lambda!(λ, α₁, α₂, β, P, u.S, u.E, u.I, u.Im, u.R)
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
    e0 = 10.0*ones(n_clases)
    i0 = zeros(n_clases) #10*ones(n_clases)
    im0 = zeros(n_clases) #100*ones(n_clases)
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
    β = beta*get_riesgos()
    #ν = nu*ones(n_clases)
    #φ = phi
    #γ = gi*ones(n_clases)
    #γₘ = gm*ones(n_clases)
    p = (a₁,a₂, β, nu, phi, gi, gm, P)
    #p = (a₁,a₂, β, ν, φ, γ, γₘ, P)
    return p
end

function set_up_parameters2(a₁,a₂, beta, nu, phi, gi, gm, τ, P, P2)
    β = beta*get_riesgos()
    ν = nu*ones(n_clases)
    φ = phi
    γ = gi*ones(n_clases)
    γₘ = gm*ones(n_clases)
    p = (a₁,a₂, β, ν, φ, γ, γₘ, τ, P,P2)
    return p
end


function set_up_parameters3(α₁,α₂, beta₁, beta₂, nu, phi, gi, gm, τ, P)
    riesgos = get_riesgos()
    β₁ = beta₁*riesgos
    β₂ = beta₁*riesgos
    transporte = 9
    compras = 4
    β₂[transporte]  = beta₂
    #β₂[1] = β₁[1] # la idea es disminuir el uso de mascarillas... fuera del hogar
    ν = nu*ones(n_clases)
    φ = phi
    γ = gi*ones(n_clases)
    γₘ = gm*ones(n_clases)
    p = (α₁,α₂, β₁, β₂, ν, φ, γ, γₘ, τ, P)
    return p
end

function get_riesgos()
    return [0.1, 0.5, 0.7, 0.7, 0.5, 0.5, 0.7, 0.7, 1.0, 0.1, 0.4, 0.1, 0.1]
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
