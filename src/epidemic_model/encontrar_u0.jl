#=
Encontrar condiciones inciales usando método propuesto por Lui, Magal para
el modelo SIRU
=#
using DifferentialEquations, Plots, Optim
include("LoadMinsalData.jl")
include("utils.jl")

##############################################################
###### Buscar parametros χ₁, χ₂, χ₃ que aproximen a los ######
###### reportados acumulados                            ######
##############################################################
aprox_cumrep(t, χ) = χ[1] * exp(χ[2] * t) - χ[3]

function chi_from_c(c, ts, data)
  a, b = linear_regression(ts, log.(data .+ c))
  (exp(b), a, c)
end

function loss_chi3(c, ts, data)
  χ = chi_from_c(c, ts, data)
  aprox = t -> aprox_cumrep(t, χ)
  sum((log.(aprox.(ts)./data)).^2)
end

function encontrar_chis(ts; lower = 10.0, upper = 1000.0)
  data = values(cumsum(TS_reportados_RM)[ts])
  loss_chi3_opt = c -> loss_chi3(c[1], ts, data)

  inner_optimizer = GradientDescent()
  results = optimize(loss_chi3_opt, [lower], [upper], [lower/2 + upper/2], Fminbox(inner_optimizer))
  χ₃ = results.minimizer[1]

  chi_from_c(χ₃, ts, data)
end

##############################################################
###### Modelo SIRU, calcular t₀ y condiciones iniciales ######
##############################################################

struct ModelParamSIRU2{T}
    # tasas de contagio
    alpha::T
    nu::T
    eta::T
    # fraccion de reportados
    phi::T
    #
    xi::T # para actualizar alpha
end



function siru!(du,u,p::ModelParamSIRU2,t)
    α = p.alpha; ν = p.nu; η = p.eta; φ = p.phi
    pₑ = 0.15; pᵢ = 0.2; pᵢₘ = 0.7;
    # Calcular derivadas
    S = u[1]; E = u[2]; I = u[3]; Im = u[4]; cI = u[5]

    du[1] = dS  = - α * S .* (pₑ * E + pᵢₘ * Im + pᵢ * I)
    du[2] = dE  = α * S .*  (pₑ * E + pᵢₘ * Im + pᵢ * I) - ν * E
    du[3] = dI  = φ * ν * E - η * I
    du[4] = dIm = (1.0 - φ) * ν * E - η * Im
    du[5] = dcI = φ * ν * E
end;



function t0_from_chis(χ)
  t0 = (1/χ[2]) * (log(χ[3]) - log(χ[1]))
  t0
end

function E0_from_chis(χ, p::ModelParamSIRU2)
  φ = p.phi; ν = p.nu;
  E0 = χ[3]*χ[2]/(φ * ν)
  E0
end

function Im0_from_chis(χ, p::ModelParamSIRU2)
  φ = p.phi; ν = p.nu; η = p.eta
  Im0 = ((1.0 - φ) * ν)/(η + χ[2]) * E0_from_chis(χ,p)
  Im0
end

function tau_from_chis(χ, p::ModelParamSIRU2, S0)
  φ = p.phi; ν = p.nu; η = p.eta

  τ = ((χ[2] + ν)/S0) * (η + χ[2])/((1.0 - φ) * ν + η + χ[2])
  τ
end

##############################################################
###### Gráficos                                         ######
##############################################################

function nombre_estados_seii()
    return [ "Susceptibles", "Expuestos", "Reportados I", "No Reportados Iᵐ", "Rep. acumulados cI"]
end

function plot_estados_siru(sol; nombres = nombre_estados_seii())
    plots = []
    for i in 1:5
        a_plot = plot(sol, vars = (0,i), title = nombres[i], label = :none)
        push!(plots, a_plot)
    end
    plot(plots..., legend = :bottomright)
end

##############################################################
###### Correr todo                                      ######
##############################################################

@time E0_from_chis(χ,_p)

ts = 15:90
χ = encontrar_chis(ts, upper = 1000)
aprox_chi = t -> aprox_cumrep(t, χ)


plot(ts, aprox_chi.(ts))
ts
t0 = t0_from_chis(χ)
ν = 0.16438183724824845; η = 0.05068548489679065; φ = 0.4984372419195904;
1/ν
1/η

ν = 1/7; η = 1/7; φ = 0.3
_p = ModelParamSIRU2(1/2, ν, η, φ, 0.1) # el 1/2 es irrelevante
E0 = E0_from_chis(χ, _p)
Im0 = Im0_from_chis(χ, _p)
I0 = 0.0
S0 = sum(total_por_clase_censo)
τ = tau_from_chis(χ, _p, S0)
p = ModelParamSIRU2(τ, ν, η, φ, 0.0)
#p = ModelParamSIRU2(0.05, 1/7, 1/7, 1/3.4, 0.0)
τ
u0 = [S0, E0,I0,Im0,0.0]
tf = 120.0
prob_inicial = ODEProblem(siru!,u0,(t0, tf),p)
sol_inicial = solve(prob_inicial);
a_plot = plot_estados_siru(sol_inicial)

inter = 1:76
scatter!(a_plot.subplots[5], full_data[1:floor(Int,tf)], msw = 0, ms = 2, label = "Reportados RM", legend = :topleft)
ts

full_data = values(cumsum(TS_reportados_RM))[ts[1]:end]
plot(cumsum(TS_reportados_RM)[2:end], yscale = :log10)
ts = 100:147
Date(2020,5,15), Date(2020,7,27)
timestamp(TS_reportados_RM)[12]
timestamp(TS_reportados_RM)[147]


function siru!(du,u,p::ModelParamSIRU2,t)
    α = p.alpha; ν = p.nu; η = p.eta; φ = p.phi
    pₑ = 0.15; pᵢ = 0.2; pᵢₘ = 0.7;
    # Calcular derivadas
    S = u[1]; E = u[2]; I = u[3]; Im = u[4]; cI = u[5]
    β = 1e-7
    du[1] = dS  = - α * β * S .* (E + Im)
    du[2] = dE  = α * β * S .*  (E + Im) - ν * E
    du[3] = dI  = φ * ν * E - η * I
    du[4] = dIm = (1.0 - φ) * ν * E - η * Im
    du[5] = dcI = φ * ν * E
end;

u0_kalman = [100., 10., 0., 0., 0.]
p_kalman = ModelParamSIRU2(1., 1/2, 1/100, 0.4, 0.0)
p_kalman = ModelParamSIRU2{Float64}(1., 0.14, 0.14, 0.3, 0.0)
prob_kalman = ODEProblem(siru!,u0,(0.0, 40.),p_kalman)
sol_kalman = solve(prob_kalman)

plot(sol_kalman, vars = (0,2:4), label = ["E(t)" "I(t)" "Iₘ(t)"])
plot(sol_kalman, vars = (0,[1,5]), label = ["S(t)" "cI(t)"])

1/0.14
# Kalman

p

p = ModelParamSIRU(0.06, 1/7, 1/7, 0.5)
x0 = [500., 3., 0., 0., 0.]
grad_f!(x, p)

tspan = (0.,10.)
prob = ODEProblem(siru!,x0,tspan,p)
sol = solve(prob);
plot(sol)

function H_x!(du_p,x,p,param::ModelParamSIRU, t)
  α = param.alpha; γₑ = param.nu; γᵢ = param.eta; φ = param.phi
  pₑ, pᵢ, pᵢₘ = prob_contagio()
  λ = pₑ * x[2] + pᵢ * x[3] + pᵢₘ * x[4]
  du_p[1] = α * λ * (p[2]-p[1])
  du_p[2] = x[1] * pₑ * α * (p[2]-p[1]) + γₑ * (p[4]-p[2]) + φ * γₑ * (p[3] + p[5] - p[4])
  du_p[3] = x[1] * pᵢ * α * (p[2]-p[1]) - γᵢ * p[3]
  du_p[4] = x[1] * pᵢₘ * α * (p[2]-p[1]) - γᵢ * p[4]
  du_p[5] = - 2 * (D(t) - x[5])
end

du_p = similar(u0[1:5])
p
H_x!(du_p, x0, u0[6:10], p, 0.0)
du_p

prob_contagio() = (p_e = 0.15, p_i = 0.2, p_im = 0.7)
pₑ, pᵢ, pᵢₘ = prob_contagio()


function pontry!(du, u, p, t)
  du_x = @view du[1:5]
  du_p = @view du[6:10]
  u_x = @view u[1:5]
  u_p = @view u[6:10]
  siru!(du_x, u_x, p, t)
  H_x!(du_p, u_x, u_p, p, t)
  du_p .*= -1.
end

p0 = 10. * ones(5)
p0[4] = 0.0
u0 = [x0; p0]

prob_pontry = ODEProblem(pontry!,u0,(0., 20.),p)
sol = solve(prob_pontry);

plot(sol, vars = (0,6:10))
#pontry!(similar(u0), u0, p, 0.0)



D = (t) -> interpol(t, values(cumsum(TS_reportados_RM)))

ts = 0.0:0.1:250.
plot(ts, D.(ts))
using Plots

function interpol(t, data)
  tₙ = floor(Int, t)
  tₙ₊₁ = tₙ + 1
  lin_aprox(t-tₙ, data[tₙ + 1], data[tₙ₊₁ + 1 ])
end


"""
t en [0,1]
"""
lin_aprox(t, x₀, x₁) = t*(x₁ - x₀) + x₀
