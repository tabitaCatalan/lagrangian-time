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

DEIS_data_array = drop_missing_and_vectorize(preparar_para_comparar_DEIS(TS_DEIS_RM, t0, t1))
lossDEIS = L2Loss(t, DEIS_data_array)

reportados_data_array = drop_missing_and_vectorize(preparar_para_comparar_reportados(TS_reportados_RM, t0,t1))
lossRep = L2Loss(t, reportados_data_array)


sum(ismissing.(UCI_data_array))

typeof(UCI_data_array)

plot(sol_cuarentena'[:, index_uci()])

index_uci()
function drop_missing_and_vectorize(array2)
  L = length(array2)
  vector = Vector{Float64}(undef, L)
  for l in 1:L
    vector[l] = Float64(array2[l])
  end
  vector
end


using Plots
scatter(preparar_para_comparar_UCI(TS_UCI_RM, t0, t1))


struct MinsalData
  func::
  data::TimeArray
end

typeof(timestamp(TS_UCI))


loss_function(sol_cuarentena, (DEIS, UCI))
generic_loss_totales(UCI.func(sol_cuarentena), UCI.data)

loss_DEIS(sol_cuarentena, TS_DEIS_RM)
fechas_sol = times_frac[1:length(sol_cuarentena.t)]
DEIS = (func = estado_DEIS, data = TS_DEIS_RM)
UCI = (func = estado_UCI, data = TS_UCI_RM)

generic_loss_totales(UCI.func(sol_cuarentena), UCI.data)

UCI.func(sol_cuarentena)
UCI.data

begin
  plot1 = plot(fechas_sol[1:end-1], estado_reportados(sol_cuarentena), title = "Reportados")
  scatter!(plot1, timestamp(TS_reportados_RM), estado_DEIS(TS_reportados_RM))

  plot2 = plot(fechas_sol, estado_UCI(sol_cuarentena), title = "UCI" )
  scatter!(plot2, timestamp(TS_UCI_RM), estado_UCI(TS_UCI_RM))

  plot3 = plot(fechas_sol[1:end-1], estado_DEIS(sol_cuarentena), title = "Fallecidos")
  scatter!(plot3, timestamp(TS_DEIS_RM), estado_DEIS(TS_DEIS_RM))

  plot(plot1, plot2, plot3, layout = (1,3))
end

UCI.func(sol_cuarentena)
UCI.data


typeof(sol_cuarentena)
times_frac





nuevo
fallecidos_real = sum(values(TS_DEIS_RM[t₀:Dates.Day(1):t₁]), dims= 2)
log.(fallecidos_real)
nuevos_muertos = sum(sol_cuarentena'[1:end-1, d] - sol_cuarentena'[2:end, d], dims = 2)
log.(nuevos_muertos)
sum(log.(fallecidos_real) - log.(nuevos_muertos[1:ultimo_dia]))^2
fallecidos_real

values

# necesito una funcion que mapee Symbol a tramo,
# para eso necesito los datos SQL.

DEIS_data[Date(2020,4,5)]
Dict([(:data, TS_DEIS_RM),(:func, )])

A = Dict([(:a, 1), (:b, 2)])

A[:a]

sol_cuarentena.prob.p

isbits(sol_cuarentena)

L2Loss

function (f::L2Loss)(sol::DiffEqBase.DESolution)
  data = f.data
  weight = f.data_weight
  diff_weight = f.differ_weight
  colloc_grad = f.colloc_grad
  dudt = f.dudt

  if sol isa DiffEqBase.AbstractEnsembleSolution
    failure = any((s.retcode != :Success for s in sol)) && any((s.retcode != :Terminated for s in sol))
  else
    failure = sol.retcode != :Success && sol != :Terminated
  end
  failure && return Inf

  sumsq = 0.0

  if weight == nothing
    @inbounds for i in 2:length(sol)
      for j in 1:length(sol[i])
        sumsq +=(data[j,i] - sol[j,i])^2
      end
      if diff_weight != nothing
          for j in 1:length(sol[i])
            if typeof(diff_weight) <: Real
              sumsq += diff_weight*((data[j,i] - data[j,i-1] - sol[j,i] + sol[j,i-1])^2)
            else
             sumsq += diff_weight[j,i]*((data[j,i] - data[j,i-1] - sol[j,i] + sol[j,i-1])^2)
            end
          end
      end
    end
  else
    @inbounds for i in 2:length(sol)
      if typeof(weight) <: Real
        for j in 1:length(sol[i])
          sumsq = sumsq + ((data[j,i] - sol[j,i])^2)*weight
        end
      else
        for j in 1:length(sol[i])
          sumsq = sumsq + ((data[j,i] - sol[j,i])^2)*weight[j,i]
        end
      end
      if diff_weight != nothing
        for j in 1:length(sol[i])
          if typeof(diff_weight) <: Real
            sumsq += diff_weight*((data[j,i] - data[j,i-1] - sol[j,i] + sol[j,i-1])^2)
          else
            sumsq += diff_weight[j,i]*((data[j,i] - data[j,i-1] - sol[j,i] + sol[j,i-1])^2)
          end
        end
      end
    end
  end
  if colloc_grad != nothing
    for i = 1:size(colloc_grad)[2]
      sol.prob.f.f(@view(dudt[:,i]), sol.u[i], sol.prob.p, sol.t[i])
    end
    sumsq += sum(abs2, x - y for (x,y) in zip(dudt, colloc_grad))
  end
  sumsq
end
