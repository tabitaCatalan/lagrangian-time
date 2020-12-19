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

struct ModelParamSIRU{T}
    # tasas de contagio
    tau::T
    nu::T
    eta::T
    # fraccion de reportados
    phi::T
end

function siru!(du,u,p::ModelParamSIRU,t)
    τ = p.tau; ν = p.nu; η = p.eta; φ = p.phi
    # Calcular derivadas
    S = u[1]; E = u[2]; I = u[3]; Im = u[4]; cI = u[5]

    du[1] = dS  = - τ * S .* (E + Im)
    du[2] = dE  = τ * S .* (E + Im) - ν * E
    du[3] = dI  = φ * ν * E - η * I
    du[4] = dIm = (1.0 - φ) * ν * E - η * Im
    du[5] = dcI = φ * ν * E
end;


function t0_from_chis(χ)
  t0 = (1/χ[2]) * (log(χ[3]) - log(χ[1]))
  t0
end

function E0_from_chis(χ, p::ModelParamSIRU)
  φ = p.phi; ν = p.nu;
  E0 = χ[3]*χ[2]/(φ * ν)
  E0
end

function Im0_from_chis(χ, p::ModelParamSIRU)
  φ = p.phi; ν = p.nu; η = p.eta
  Im0 = ((1.0 - φ) * ν)/(η + χ[2]) * E0_from_chis(χ,p)
  Im0
end

function tau_from_chis(χ, p::ModelParamSIRU, S0)
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

ts = 15:91
χ = encontrar_chis(ts)
t0 = t0_from_chis(χ)
ν = 1/7; η = 1/7; φ = 0.3
_p = ModelParamSIRU(1/2, ν, η, φ) # el 1/2 es irrelevante
E0 = E0_from_chis(χ, _p)
Im0 = Im0_from_chis(χ, _p)
I0 = 0.0
S0 = sum(total_por_clase_censo)
τ = tau_from_chis(χ, _p, S0)
p = ModelParamSIRU(τ, 1/7, 1/7, 1/3.4)

u0 = [S0, E0,I0,Im0,0.0]
tf = 50.0
prob_inicial = ODEProblem(siru!,u0,(t0, tf),p)
sol_inicial = solve(prob_inicial);
a_plot = plot_estados_siru(sol_inicial)

inter = 1:floor(Int, tf-t0)
scatter!(a_plot.subplots[5], ts[inter], data[inter], msw = 0, ms = 2, label = "Reportados RM")
a_plot

data
