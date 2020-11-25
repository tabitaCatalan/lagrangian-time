#=
En este archivo hay funciones para estimar los parámetros del modelo usando
mínimos cuadrados.
=#

using DifferentialEquations
using DiffEqParamEstim
############################
### Funciones auxiliares ###
############################

##### Índices de cada estado #####

"""
  rango_estado(numero_estado, n_clases)
Al obtener una solución del modelo SEImIRHHcD con **DifferentialEquations.jl**,
puesto que es un sistema de ecuaciones, cada estado es un vector de clases
asociado a una ecuación diferencial. Para obtener las soluciones es útil contar
con los rangos de índices en que se encuentran los distintos estados.
# Argumentos
- `numero_estado`: número asociado al estado. Son los siguientes:
  *Susceptibles (S)* = 1; *Expuestos (E)* = 2; *Infectados (I)* = 3;
  *Infectados mild (Iᵐ)* = 4; *Recuperados (R)* = 4; *Hospitalizados (H)* = 5;
  *Hospitalizados UCI (Hc)* = 6; *Fallecidos (D)* = 7;
- `n_clases`: número de clases.
# Ejemplos
Si suponemos que `sol` es una solución al modelo con 6 clases, entonces podemos
graficar a los infectados (`numero_estado = 3`) haciendo
```julia
infectados = rango_estado(3,6)
plot(sol, vars = (0,infectados))
```
"""
function rango_estado(numero_estado, n_clases)
  return (numero_estado - 1) * n_clases + 1: numero_estado * n_clases
end

index_susc(;n_clases = 18) = rango_estado(1, n_clases)
index_infec(; n_clases = 18) = rango_estado(3, n_clases)
index_uci(;n_clases = 18) = rango_estado(7, n_clases)
index_muertos(;n_clases = 18) = rango_estado(8, n_clases)

##### Preparar solución y datos para comparar #####
"""
  nuevos_diarios(sol, estado; index_grupo = 1:18)
Calcula para un estado la diferencia entre el número de personas entre un día
y el anterior.
"""
function nuevos_diarios(sol::DiffEqBase.DESolution, estado; index_grupo = 1:18, dias)
    sum(sol'[2:dias+1, estado[index_grupo]] - sol'[1:dias, estado[index_grupo]], dims = 2)
end

cuantos_dias(t0::Date, t1::Date) = (t1-t0).value

function is_in(dates_1::Vector{Date}, dates_2::Vector{Date})
  f(date) = date in dates_2
  f.(dates_1)
end

function preparar_para_comparar_UCI(sol::OrdinaryDiffEq.ODECompositeSolution, t0::Date, tf::Date)
  dias = cuantos_dias(t0,tf)
  sum(sol'[1:dias, index_uci()], dims = 2)
end

function preparar_para_comparar_DEIS(sol::OrdinaryDiffEq.ODECompositeSolution, t0::Date, tf::Date)
  dias = cuantos_dias(t0,tf)
  nuevos_diarios(sol, index_muertos(), dias = dias)
end
function preparar_para_comparar_reportados(sol::OrdinaryDiffEq.ODECompositeSolution, t0::Date, tf::Date)
  dias = cuantos_dias(t0,tf)
  - nuevos_diarios(sol, index_susc(), dias = dias)
end

function suma_por_fila_y_filtrar_fecha(TS::TimeArray, t0::Date, tf::Date)
  sum(values(TS[t0:Dates.Day(1):tf]), dims = 2)
end

function start_and_finish_dates()
  t0 = Date(2020,4,12)
  tf = Date(2020,7,1)
  t0, tf
end

function drop_missing_and_vectorize(array2)
  L = length(array2)
  vector = Vector{Float64}(undef, L)
  for l in 1:L
    vector[l] = Float64(array2[l])
  end
  vector
end

t0, t1 = start_and_finish_dates()

############################
### Funciones de pérdida ###
############################

function is_failure(sol::DiffEqBase.DESolution)
  if sol isa DiffEqBase.AbstractEnsembleSolution
    failure = any((s.retcode != :Success for s in sol)) && any((s.retcode != :Terminated for s in sol))
  else
    failure = sol.retcode != :Success && sol != :Terminated
  end
  failure
end

############## UCI #################

struct LossUCI{T,D} <: DiffEqBase.DECostFunction
  t::T
  data::D
end

function estadoUCI(t, sol)
  sum(sol'[t, index_uci()], dims = 2)
end

function (f::LossUCI)(sol::DiffEqBase.DESolution)
  is_failure(sol) && return Inf

  sum((estadoUCI(f.t, sol) - f.data).^2)
end

function construir_loss_UCI(TS_UCI::TimeArray, t0::Date, t1::Date)
  t_dates = collect(t0:Dates.Day(1):t1)
  t = collect(1:cuantos_dias(t0,t1)+1)
  UCI_data_array = drop_missing_and_vectorize(suma_por_fila_y_filtrar_fecha(TS_UCI_RM, t0,t1))
  dias_comparables = is_in(t_dates, timestamp(TS_UCI_RM[t_dates]))
  lossUCI = LossUCI(t[dias_comparables], UCI_data_array)
  lossUCI
end

lossUCI = construir_loss_UCI(TS_UCI_RM, t0, t1)
scatter(lossUCI.t, lossUCI.data, title = "Datos UCI", legend =:none)

lossUCI(sol_cuarentena)

########### Fallecidos ################

struct LossDEIS{T,D} <: DiffEqBase.DECostFunction
  dias::T
  data::D
end

function estadoDEIS(dias, sol)
    nuevos_diarios(sol, index_muertos(),dias = dias + 1)
end


function (f::LossDEIS)(sol::DiffEqBase.DESolution)
  is_failure(sol) && return Inf

  sum(( estadoDEIS(f.dias, sol)- f.data).^2)
end


function construir_loss_DEIS(TS_DEIS::TimeArray, t0::Date, t1::Date)
  DEIS_data_array = drop_missing_and_vectorize(suma_por_fila_y_filtrar_fecha(TS_DEIS_RM, t0, t1))
  lossDEIS = LossDEIS(cuantos_dias(t0,t1), DEIS_data_array)
  lossDEIS
end

lossDEIS = construir_loss_DEIS(TS_DEIS_RM, t0, t1)
scatter(lossDEIS.data, title = "Datos DEIS")

################## Reportados #####################
struct LossRep{T,D} <: DiffEqBase.DECostFunction
  dias::T
  data::D
end

function estadoRep(dias, sol)
  - nuevos_diarios(sol, index_susc(),dias =  dias + 1)
end


function (f::LossRep)(sol::DiffEqBase.DESolution)
  is_failure(sol) && return Inf

  sum(( estadoRep(f.dias, sol) - f.data).^2)
end


function construir_loss_rep(TS_rep::TimeArray, t0::Date, t1::Date)
  reportados_data_array = drop_missing_and_vectorize(suma_por_fila_y_filtrar_fecha(TS_rep, t0, t1))
  lossRep = LossRep(cuantos_dias(t0,t1), reportados_data_array)
  lossRep
end

lossRep = construir_loss_rep(TS_reportados_RM, t0, t1)
scatter(lossRep.data, title = "Datos Reportados")
################### Total ########################

loss(sol) = lossUCI(sol) + lossDEIS(sol) + lossRep(sol)

####################################################
### Optimizar los parámetros                     ###
### Requiere haber corrido run_model_and_plot.jl ###
####################################################

copy_data_u0 = copy(data_u0)
prob_generator = (prob,p) -> remake(prob,u0 = update_initial_condition!(copy_data_u0, p), p=(p0_model_cte, p0_lmbda_cte))
prob_generator_full = (prob,p) -> remake(prob,u0 = update_initial_condition!(copy_data_u0, p), p=(p[9:17],p[18:22]))

#using Traceur

#@time cost_function(p0)

saveat = 1.0
cost_function = build_loss_objective(prob_cuarentena,Tsit5(),
  loss, prob_generator = prob_generator,
  saveat = saveat,
  maxiters = 10000
  )

cost_function_full = build_loss_objective(prob_cuarentena,Tsit5(),
  loss, prob_generator = prob_generator_full,
  saveat = saveat,
  maxiters = 10000
  )
#using Zygote

cost_function_full(p0)
cost_function_full(p_10kiter)


#function g!(G, x)
#    G .=  cost_function'(x)
#end
prob_cuarentena

using Optim


function update_initial_condition!(data_u0::MyDataArray, u0_params)
  data_u0.x.S = u0_params[1] * data_u0.total_por_clase
  data_u0.x.E = u0_params[2] * data_u0.total_por_clase
  data_u0.x.I = u0_params[3] * data_u0.total_por_clase
  data_u0.x.Im = u0_params[4] * data_u0.total_por_clase
  data_u0.x.R = u0_params[5] * data_u0.total_por_clase
  data_u0.x.H = u0_params[6] * data_u0.total_por_clase
  data_u0.x.Hc = u0_params[7] * data_u0.total_por_clase
  data_u0.x.D = u0_params[8] * data_u0.total_por_clase
  data_u0
end

data_u0.total_por_clase
lossUCI.data
lossRep.data

s0 = 0.9; e0 = 0.02; i0 = 0.02; im0 = 0.01; r0 = 0.02; h0 = 0.01; hc0=0.01; d0=0.01;
u0_params = [s0, e0, i0, im0, r0, h0, hc0, d0]
sum(u0_params)
lower_u0 = [0., 0., 0., 0., 0., 0., 0., 0.]
upper_u0 = [1., 1., 1., 1., 1., 1., 1., 1.]

const p0_model_cte = p0_model
p0_model = [γₑ, γᵢ, γᵢₘ, γₕ, γₕ_c, φₑᵢ, φᵢᵣ, φₕᵣ, φ_d]
lower_model = [0.01, 0.01, 0.01, 0.01, 0.01, 0.0, 0.0, 0.0, 0.0]
upper_model = [5., 5, 5., 5., 5., 1.0, 1.0, 1.0, 1.0]

const p0_lmbda_cte = p0_lmbda
p0_lmbda = [1.0, β, pₑ, 1.0, pᵢₘ]
lower_lmbda = [0.5, 0.1, 0.0, 0.0, 0.0]
upper_lmbda = [1.0, 6.0, 1.0, 1.0, 1.0]


p0 = [u0_params;p0_model; p0_lmbda]
lower = [lower_u0; lower_model; lower_lmbda]
upper = [upper_u0; upper_model; upper_lmbda]

prob2 = prob_generator(prob_cuarentena, p0)
sol2 = solve(prob2, saveat = 1.0)


cost_function(u0_params)
using Flux
res = Optim.optimize(
  cost_function,
  lower_u0, upper_u0,
  u0_params,
  Fminbox(Optim.BFGS()), Optim.Options(iterations = 1)
)


using BlackBoxOptim

bboptimize(cost_function; SearchRange = (i -> (lower_u0[i], upper_u0[i])).(1:8))
p_res = [0.0981235, 0.000751838, 4.38449e-5, 0.000295247, 0.117949, 0.000234054, 2.25681e-5, 0.0352279]

res_full = bboptimize(cost_function_full; SearchRange = (i -> (lower[i], upper[i])).(1:22))
p_10kiter = [0.100961, 0.00440102, 0.0613713, 0.0991362, 0.508734, 0.726285, 0.000135861, 0.608562, 0.0100703, 3.82787, 3.98219, 0.0182238, 0.0705907, 0.280078, 0.745378, 0.999952, 0.00671096, 0.722137, 0.970178, 0.929587, 0.96598, 0.00962657]

opt_pro_full = bbsetup(cost_function_full; SearchRange = (i -> (lower[i], upper[i])).(1:22), TraceMode = :silent);
bboptimize(opt_pro_full)

res_full = bboptimize(cost_function_full; SearchRange = , MaxSteps=50000)

res_full.elapsed_time
prob_ini = prob_generator(prob_cuarentena,p0)
sol_ini = solve(prob_ini, saveat = 1.0)

plot_comparar_datos(sol_ini)
plot_comparar_datos(sol_res)
plot(sol_res)

using Plots
scatter(preparar_para_comparar_UCI(TS_UCI_RM, t0, t1))




cuantos_dias(t0,t1)

fechas_sol = t0:Dates.Day(1):t1
function plot_comparar_datos(sol)
  fechas = fechas_sol[1:cuantos_dias(t0,t1)]

  plot1 = plot(fechas, preparar_para_comparar_reportados(sol, t0, t1), title = "Reportados")
  scatter!(plot1, fechas, lossRep.data)

  plot2 = plot(fechas, preparar_para_comparar_UCI(sol, t0,t1), title = "UCI" )
  scatter!(plot2, fechas[lossUCI.t[1:end-1]], lossUCI.data[1:end-1])

  plot3 = plot(fechas, preparar_para_comparar_DEIS(sol,t0,t1), title = "Fallecidos")
  scatter!(plot3,fechas, lossDEIS.data)

  plot(plot1, plot2, plot3, layout = (1,3))
end

fechas = fechas_sol[1:cuantos_dias(t0,t1)]
length(fechas)
lossUCI.t[end]
plot_comparar_datos(sol_res)
preparar_para_comparar_DEIS(sol2, t0, t1)
lossUCI.data
UCI_data_array[1]
DEIS_data_array[1]
reportados_data_array[1]
t1

fallecidos_real = sum(values(TS_DEIS_RM[t₀:Dates.Day(1):t₁]), dims= 2)
log.(fallecidos_real)
nuevos_muertos = sum(sol_cuarentena'[1:end-1, d] - sol_cuarentena'[2:end, d], dims = 2)
log.(nuevos_muertos)
sum(log.(fallecidos_real) - log.(nuevos_muertos[1:ultimo_dia]))^2
fallecidos_real


# necesito una funcion que mapee Symbol a tramo,
# para eso necesito los datos SQL.
