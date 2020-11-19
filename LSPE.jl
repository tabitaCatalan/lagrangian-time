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
Calcula para un estado la diferencia entre el número de personas en entre un día
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
  nuevos_diarios(sol, index_muertos(), dias)
end
function preparar_para_comparar_reportados(sol::OrdinaryDiffEq.ODECompositeSolution, t0::Date, tf::Date)
  dias = cuantos_dias(t0,tf)
  - nuevos_diarios(sol, index_susc(), dias)
end

function suma_por_fila_y_filtrar_fecha(TS::TimeArray, t0::Date, tf::Date)
  sum(values(TS[t0:Dates.Day(1):tf]), dims = 2)
end

function preparar_para_comparar_UCI(TS_UCI::TimeArray, t0::Date, tf::Date)
  suma_por_fila_y_filtrar_fecha(TS_UCI, t0, tf)
end

function preparar_para_comparar_DEIS(TS_DEIS::TimeArray, t0::Date, tf::Date)
  suma_por_fila_y_filtrar_fecha(TS_DEIS, t0, tf)
end

function preparar_para_comparar_reportados(TS_reportados::TimeArray, t0::Date, tf::Date)
  suma_por_fila_y_filtrar_fecha(TS_reportados, t0, tf)
end

function start_and_finish_dates()
  t0 = Date(2020,4,12)
  tf = Date(2020,7,1)
  t0, tf
end

############################
### Funciones de pérdida ###
############################


#################################################
### Usar Datos:
### Requiere haber hecho run de LoadMinsalData.jl
#################################################
function drop_missing_and_vectorize(array2)
  L = length(array2)
  vector = Vector{Float64}(undef, L)
  for l in 1:L
    vector[l] = Float64(array2[l])
  end
  vector
end

t0, t1 = start_and_finish_dates()

UCI_data_array = drop_missing_and_vectorize(preparar_para_comparar_UCI(TS_UCI_RM, t0, t1))
DEIS_data_array = drop_missing_and_vectorize(preparar_para_comparar_DEIS(TS_DEIS_RM, t0, t1))
reportados_data_array = drop_missing_and_vectorize(preparar_para_comparar_reportados(TS_reportados_RM, t0,t1))


################################################
function is_failure(sol::DiffEqBase.DESolution)
  if sol isa DiffEqBase.AbstractEnsembleSolution
    failure = any((s.retcode != :Success for s in sol)) && any((s.retcode != :Terminated for s in sol))
  else
    failure = sol.retcode != :Success && sol != :Terminated
  end
  failure
end

struct LossUCI{T,D} <: DiffEqBase.DECostFunction
  t::T
  data::D
end

function (f::LossUCI)(sol::DiffEqBase.DESolution)
  is_failure(sol) && return Inf

  sum((sum(sol'[f.t, index_uci()], dims = 2) - f.data).^2)
end

t_dates = collect(t0:Dates.Day(1):t1)
t = collect(1:cuantos_dias(t0,t1)+1)
UCI_data_array = drop_missing_and_vectorize(preparar_para_comparar_UCI(TS_UCI_RM, t0,t1))
dias_comparables = is_in(t_dates, timestamp(TS_UCI_RM[t_dates]))
lossUCI = LossUCI(t[dias_comparables], UCI_data_array)
lossUCI(sol_cuarentena)

########### Fallecidos ################

struct LossDEIS{T,D} <: DiffEqBase.DECostFunction
  dias::T
  data::D
end

function (f::LossDEIS)(sol::DiffEqBase.DESolution)
  is_failure(sol) && return Inf

  sum((nuevos_diarios(sol, index_muertos(),dias =  f.dias + 1) - f.data).^2)
end


lossDEIS = LossDEIS(cuantos_dias(t0,t1), DEIS_data_array)

lossDEIS(sol_cuarentena)

######### Reportados #########################
struct LossRep{T,D} <: DiffEqBase.DECostFunction
  dias::T
  data::D
end

function (f::LossRep)(sol::DiffEqBase.DESolution)
  is_failure(sol) && return Inf

  sum((nuevos_diarios(sol, index_susc(),dias =  f.dias + 1) + f.data).^2)
end

lossRep = LossRep(cuantos_dias(t0,t1), reportados_data_array)
lossRep(sol_cuarentena)

loss(sol) = lossUCI(sol) + lossDEIS(sol) + lossRep(sol)
loss(sol_normal)

lossDEIS(sol_normal )

sol_cuarentena'
sol_normal'
prob_generator = (prob,p) -> remake(prob,p=p)

save_at
cost_function = build_loss_objective(prob_cuarentena,Tsit5(),loss, prob_generator = prob_generator,  saveat = save_at)

cost_function(p0)

using Optim

p0 = [γₑ, γᵢ, γᵢₘ, γₕ, γₕ_c, φₑᵢ, φᵢᵣ, φₕᵣ, φ_d, 1.0, β, pₑ, 1.0, pᵢₘ]

Optim.optimize(cost_function, p0, Optim.BFGS())

loss(sol_cuarentena)






using Plots
scatter(preparar_para_comparar_UCI(TS_UCI_RM, t0, t1))



begin
  plot1 = plot(fechas_sol[1:end-1], estado_reportados(sol_cuarentena), title = "Reportados")
  scatter!(plot1, timestamp(TS_reportados_RM), estado_DEIS(TS_reportados_RM))

  plot2 = plot(fechas_sol, estado_UCI(sol_cuarentena), title = "UCI" )
  scatter!(plot2, timestamp(TS_UCI_RM), estado_UCI(TS_UCI_RM))

  plot3 = plot(fechas_sol[1:end-1], estado_DEIS(sol_cuarentena), title = "Fallecidos")
  scatter!(plot3, timestamp(TS_DEIS_RM), estado_DEIS(TS_DEIS_RM))

  plot(plot1, plot2, plot3, layout = (1,3))
end

fallecidos_real = sum(values(TS_DEIS_RM[t₀:Dates.Day(1):t₁]), dims= 2)
log.(fallecidos_real)
nuevos_muertos = sum(sol_cuarentena'[1:end-1, d] - sol_cuarentena'[2:end, d], dims = 2)
log.(nuevos_muertos)
sum(log.(fallecidos_real) - log.(nuevos_muertos[1:ultimo_dia]))^2
fallecidos_real


# necesito una funcion que mapee Symbol a tramo,
# para eso necesito los datos SQL.
