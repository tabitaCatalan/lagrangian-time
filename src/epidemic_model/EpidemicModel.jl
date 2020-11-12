#=
Este archivo contiene el modelo a usar para modelar la epidemia (SEIIᵐR).
Incluye además funciones para leer datos desde MATLAB.
=#

## Importar dependencias
using ComponentArrays
using DifferentialEquations
using StaticArrays

"""
    MyDataArray
Esta estructura está pensada para ser usada en el modelo de **EpidemicModel.jl**.
Surge de la necesidad de tener acceso a variables globales eficientes. Puede
usarse en el solver de **DifferentialEquations.jl**.
# Campos
- `x`: Estado actual
- `P_normal`: matriz de tiempos de residencia normal (sin medidas preventivas)
- `P_cuarentena`: matriz de tiempos de residencia en cuarentena. Del mismo
    tamaño que `P_normal`.
- `frac_pobla_cuarentena`: matriz de fraccion de personas
    en cuarentena dependiendo del tiempo. Es de tamño `numero_dias`x3. En la
    coordenada `i,j` contiene la fracción de personas de la clase social `j` que
    están en cuarentena el día `i`.
"""
struct MyDataArray{T} <: DEDataArray{T,1}
    x::ComponentVector{T}
    P_normal::Array{T,2}
    P_cuarentena::Array{T,2}
    frac_pobla_cuarentena::Array{T,2}
end

"""
    LambdaParam
Esta estructura contiene los parametros para calcular la tasa de contagio que
deben ser ajustados.
# Campos
- `alpha`: parámetro de control, relacionado al distanciamiento social y la
    fracción de personas en cuarentena. Debería ser un valor en [0,1].
- `beta`: parámetro de ajuste de los riesgos relativos. Se tendrá un vector fijo
    con valores de riesgo entre 0 y 1 para cada uno de los ambientes. Sin
    embargo, para ajustar el modelo es necesario ponderar esos valores por `beta`.
- `p_E`: probabilidad de que un susceptible sea contagiado por un expuesto.
- `p_I`: probabilidad de que un susceptible sea contagiado por un sintomático.
- `p_Im`: probabilidad de que un susceptible sea contagiado por un asintomático.
"""
struct LambdaParam{T}
    alpha::T
    beta::T
    p_E::T
    p_I::T
    p_Im::T
end

"""
    ModelParam
Esta estructura contiene los parámetros del modelo SEIIRHHD que deben ajustarse.
# Campos
## Tasas de transición
Todas las tasas están medidas en 1/día. Eso quiere decir que si la tasa con
que las personas en una etapa A de la enfermedad pasan a una etapa B es γ,
entonces en promedio una persona tarda 1/γ días en pasar de la etapa A a la
etapa B. Se utilizan valores de γ de tal forma que 1/γ esté entre 1 y 14 días.
- `gamma_e`: tasa de salida del estado E
- `gamma_i`: tasa de salida del estado I
- `gamma_im`: tasa de salida del estado Iᵐ
- `gamma_h`: tasa de salida del estado H
- `gamma_hc`: tasa de salida del estado Hᶜ
## Fracciones
Las fracciones permiten bifurcar a la población que sale de un estado en dos
posibles estados. Toman valores en [0,1].
- `phi_ei`: fracción de personas que al salir del estado E (expuestos) pasan a
    ser infectados sintomáticos (estado I). La fracción complementaria
    `(1 - phi_ei)` pasará al estado Iᵐ (infectados asintomáticos)
- `phi_ir`: fracción de personas que al salir del estado I (infectados) se
    recuperan, pasando al estado R. La fracción complementaria `(1 - phi_ir)` se
    enferma lo suficiente como para ser hospitalizada (estado H).
- `phi_hr`: fracción de personas que estando hospitalizadas (estado H) logran
    recuperarse (estado R). La fracción complementaria `(1 - phi_hr)` empeora,
    pasando a la UCI (Unidad de Cuidados Intensivos) (estado Hᶜ).
- `phi_d`: fracción de personas críticas (estado Hᶜ) que fallecen (estado D). La
    fracción complementaria logra recuperarse y pasa a estar hospitalizado
    (estado H), pudiendo eventualmente volver a empeorar.
- `lambda_param::LambdaParam`: parámetros para la tasa de contagio. Ver la
    descripción de `LambdaParam` para más detalles.
"""
struct ModelParam{T}
    gamma_e::T
    gamma_i::T
    gamma_im::T
    gamma_h::T
    gamma_hc::T
    phi_ei::T
    phi_ir::T
    phi_hr::T
    phi_d::T
    # podría añadir restricciones de integridad como que phi ∈ [0,1]
    # falta un parametro para el lambda
    lambda_param::LambdaParam{T}
end


"""
    index_clases()
# Devuelve los indices asociados a las distintas clases socioeconómicas en la
matriz `P`.
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

"""
    seiirhhd!(du,u,p,t)
Modelo epidemiológico tipo SEIIRHHD
# Arguments
- `du::MyDataArray{Float64}`:
- `u::MyDataArray{Float64}`
- `p::ModelParam`
- `t`:
"""
function seiirhhd!(du::MyDataArray{Float64},u::MyDataArray{Float64},p::ModelParam{Float64},t)
    # Extraer parametros
    γₑ = p.gamma_e; γᵢ = p.gamma_i; γᵢₘ = p.gamma_im
    γₕ = p.gamma_h; γₕ_c = p.gamma_hc
    φₑᵢ = p.phi_ei; φᵢᵣ = p.phi_ir; φₕᵣ = p.phi_hr; φ_d = p.phi_d
    # Calcular parametros a tiempo t
    P = similar(u.P_normal)
    matrix_ponderation!(P, u.P_normal, u.P_cuarentena, u.frac_pobla_cuarentena[floor(Int,t)+1, :])
    λ = Array{Float64, 1}(undef, size(u.P_normal)[1])
    calcular_lambda!(λ, p.lambda_param, P, u)
    # Calcular derivada
    du.x.S  = -λ .* u.x.S
    du.x.E  = λ .* u.x.S - γₑ * u.x.E
    du.x.I  = φₑᵢ * γₑ * u.x.E - γᵢ * u.x.I
    du.x.Im = (1.0 - φₑᵢ) * γₑ * u.x.E - γᵢₘ * u.x.Im
    du.x.R  = γᵢₘ * u.x.Im + φᵢᵣ * γᵢ * u.x.I + φₕᵣ * γₕ * u.x.H
    du.x.H = (1.0 - φᵢᵣ) * γᵢ * u.x.I + (1.0 - φ_d) * γₕ_c * u.x.Hc - γₕ * u.x.H
    du.x.Hc = (1.0 - φₕᵣ) * γₕ * u.x.H - φ_d * γₕ_c * u.x.Hc
    du.x.D = φ_d * γₕ_c * u.x.Hc
end;

"""
    calcular_lambda!(λ, lambda_param::LambdaParam, P, u::MyDataArray)
Calcula la tasa de contagio (la sobreescribe en la variable λ)
``
 λ_i(t) = Σ_{j=1}^m β_{j}p^S_{ij}
\\left(
p_E
\\frac{ Σ_{k=1}^{n} p^E_{kj}E_k}{Σ_{k=1}^{n}p^E_{kj}N_k}
+ p_{I}
\\frac{Σ_{k=1}^{n} p^I_{ kj}I_k }{Σ_{k=1}^{n}p^I_{kj}N_k}
+ p_{I^m}
\\frac{Σ_{k=1}^{n}p^{I^m}{kj}I^m_k}{Σ_{k=1}^{n}p^{I^m}_{kj}N_k}
 \\right)
``
# Argumentos
- `lambda::Vector`: Su largo debe coincidir con el numero de filas de P
- `lambda_param::LambdaParam`: parámetros para calcular la tasa de contagio. Ver
    la descripción de `LambdaParam` para más detalles.
- `P`: matrix de tiempos de residencia.
- `u:MyDataArray`: estado actual del sistema.
"""
function calcular_lambda!(λ, lambda_param::LambdaParam{Float64}, P, u::MyDataArray{Float64})
    α = p.lambda_param.alpha; β = p.lambda_param.beta .* get_riesgos()
    pₑ = lambda_param.p_E; pᵢ = lambda_param.p_I; pᵢₘ = lambda_param.p_Im
    S = u.x.S; E = u.x.E; I = u.x.I; Iᵐ = u.x.Im; R = u.x.R
    hogar = 1
    N = S + E + I + Iᵐ + R
    λ .= P*(β .* ( pₑ*(P' * E)./(P' * N) + pᵢₘ*(P' * Iᵐ)./(P' * N) ))
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
    h0 = zeros(n_clases)
    hc0 = zeros(n_clases)
    d0 = zeros(n_clases)

    u0 = ComponentArray(S = s0, E = e0, Im = im0, I = i0, R = r0, H = h0, Hc = hc0, D = d0)
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
function set_up_parameters(a₁,a₂, beta, nu, phi, gi, gm)
    β = beta*get_riesgos()
    #ν = nu*ones(n_clases)
    #φ = phi
    #γ = gi*ones(n_clases)
    #γₘ = gm*ones(n_clases)
    p = (a₁,a₂, β, nu, phi, gi, gm)
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

function get_riesgos!(beta)
    beta = [0.1, 0.5, 0.7, 0.7, 0.5, 0.5, 0.7, 0.7, 1.0, 0.1, 0.4, 0.1, 0.1]
end

"""
    make_filename(a, beta, nu, phi, gi, gm)
Devuelve un String que puede usarse para nombrar archivos, y que incluye
los parametros usados. La notación es:
`_` + nombre del parámetro + valor del parámetro
Para evitar problemas, se usa `-` como separador decimal.
"""
function make_filename(p::ModelParam{Float64})
    ge = round(p.gamma_e, digits = 2);
    gi = round(p.gamma_i, digits = 2);
    gim = round(p.gamma_im, digits = 2);
    gh = round(p.gamma_h, digits = 2);
    ghc = round(p.gamma_hc, digits = 2);
    phiei = round(p.phi_ei, digits = 2);
    phiir = round(p.phi_ir, digits = 2);
    phihr = round(p.phi_hr, digits = 2);
    phid = round(p.phi_d, digits = 2);
    alpha = round(p.lambda_param.alpha, digits = 2);
    beta = round(p.lambda_param.beta, digits = 2);
    pe = round(p.lambda_param.p_E, digits = 2);
    pin = round(p.lambda_param.p_I, digits = 2);
    pim = round(p.lambda_param.p_Im, digits = 2);

    filename = "_ge$ge _gi$gi _gim$gim _gh$gh _ghc$ghc _phiei$phiei _phiir$phiir _phihr$phihr _phid$phid _alpha$alpha _beta$beta _pe$pe _pin$pin _pim$pim"
    filename = replace(filename, " " => "")
    filename = replace(filename, "." => "-")
    println(filename)
    return filename
end
