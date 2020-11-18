#=
En este archivo hay funciones para estimar los parámetros del modelo usando
mínimos cuadrados.
=#

using DifferentialEquations

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
function nuevos_diarios(sol::OrdinaryDiffEq.ODECompositeSolution, estado; index_grupo = 1:18, dias)
    sum(sol'[2:dias+1, estado[index_grupo]] - sol'[1:dias, estado[index_grupo]], dims = 2)
end

cuantos_dias(t0::Date, t1::Date) = (t1-t0).value

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


"""
Creo que data debería ser un diccionario o algo así
la idea es entregar los datos, una función de la solución
y un `timestamp` donde comparar.
"""
function loss_function(sol, data_sets)
   tot_loss = 0.0
   if any((s.retcode != :Success for s in sol))
     tot_loss = Inf
   else
     # calculation for the loss here
     for data in data_sets
       tot_loss += generic_loss_totales(data.func(sol), data.data)
     end
   end
   tot_loss
end


"""
Calcula la diferencia al cuadrado entre la serie de tiempo real para el número
de personas en algún estado y la serie que predice la solución.
# Argumentos
- `sol`: una solución obtenida con `solve` sobre un `ODEProblem`.
- `index_estado:` rango asociado al estado que se busca. En general será
  `n_estado * n_clases + 1: n_estado * (n_clases + 1)`
"""
function generic_loss_totales(casos_por_dia, TS_data)
  t₀, t₁ = start_and_finish_dates()
  ultimo_dia = cuantos_dias(t₀, t₁)
  nuevos_por_dia_real = suma_por_fila_y_filtrar_fecha(TS_data, t₀, t₁)
  sum((nuevos_por_dia_real) - (casos_por_dia[1:ultimo_dia+1]))^2
end

#################################################
### Usar Datos:
### Requiere haber hecho run de LoadMinsalData.jl
#################################################
cuantos_dias(t0,t1)
UCI_data_array = preparar_para_comparar_UCI(TS_UCI_RM, t0,t1)
prepa

using Plots
scatter(preparar_para_comparar_UCI(TS_UCI_RM, t0, t1))


struct MinsalData
  func::
  data::TimeArray
end


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
