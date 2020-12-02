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

function nuevos_diarios(sol::DiffEqBase.DESolution, estado; index_grupo = 1:18)
    sum(sol'[2:end, estado[index_grupo]] - sol'[1:end-1, estado[index_grupo]], dims = 2)
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

############## Estructura de Datos #################

"""
Recibe un vector ordenado (creciente) de `Date`s, y devuelve un rango de las
fechas que están en [t0,tf].
"""
function index_dias_entre_t0_y_tf(dias::Vector{Date}, t0::Date, tf::Date)
  if t0 > tf
    error("t0 debe ser una fecha anterior que tf. Entregó t0 = $t0 y tf = $tf.")
  end
  primero = findfirst(dias .>= t0)
  ultimo = findlast(dias .<= tf)
  if isnothing(primero) | isnothing(ultimo) # no hay datos en el intervalo [t0,tf]
    error("No hay datos entre $t0 y $tf")
  else
   primero:ultimo
 end
end

#= TEST
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,3), Date(2020,3,5)) == 2:2
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,4), Date(2020,3,4)) == 2:2
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,3), Date(2020,3,6)) == 2:3
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,2), Date(2020,3,5)) == 1:2
# Estos deben dar error
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,6), Date(2020,3,5))
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,7), Date(2020,3,8))
index_dias_entre_t0_y_tf([Date(2020,3,2), Date(2020,3,4), Date(2020,3,6)], Date(2020,3,1), Date(2020,3,1))
=#


struct LossData{D<:Date,T<:Real,I<:Integer} <: DiffEqBase.DECostFunction
  t0::D
  tf::D
  dias::Vector{D}
  data::Vector{T}
  index_dias::Vector{I}

  function LossData(dias::Vector{Date}, data::Vector{T}, t0_sol::Date, tf_sol::Date) where {T<:Real}
    if length(data) != length(dias)
      error("Los vectores `dias` y `data` deben ser del mismo largo.")
    end
    index_en_rango = index_dias_entre_t0_y_tf(dias, t0_sol, tf_sol)

    t0 = dias[index_en_rango[1]]
    tf = dias[index_en_rango[end]]

    full_dias = collect(t0:Dates.Day(1):tf)
    full_index = collect(1:length(full_dias))
    index_dias = full_index[is_in(full_dias, dias)]

    new{Date,T,eltype(index_dias)}(t0,tf,dias[index_en_rango],data[index_en_rango],index_dias)
  end
end

##### Constructor externos ######
function LossData(TS::TimeArray, t0_sol::Date, tf_sol::Date)
  dias = timestamp(TS)
  data = drop_missing_and_vectorize(suma_por_fila_y_filtrar_fecha(TS, dias[1],dias[end]))

  LossData(dias,data,t0_sol, tf_sol)
end

function dia_final_sol(sol::DiffEqBase.DESolution, t0_sol::Date)
  n_dias = Integer(sol_cuarentena.t[end] - sol_cuarentena.t[1]) + 1
  tf_sol = t0_sol + Dates.Day(n_dias - 1)
  tf_sol
end

function (f::LossData)(sol_vec, t0_sol::Date)
  index_comparable = f.index_dias .+ cuantos_dias(t0_sol, f.t0)
  sum((log.(sol_vec[index_comparable]) - log.(f.data)).^2)
end

cuantos_dias(t0_sol +Dates.Day(1), lossRep.t0)
#=
"""
  LossData(sol_vec, t0_sol::Date)
Permite comparar los datos a un vector obtenido a partir
de la solución a una ecuación diferencial.
# Argumentos
- `sol_vec::Vector` es un vector de datos obtenidos a
  partir de la solución. Puede ser, por ejemplo, el
  número de nuevos casos diarios, el total de infectados
  por día, etc. Suponemos que es un vector guardado cada
  un día (es decir, que al usar `solve` se tenía un
  `saveat = 1.0`), de manera consecutiva (es una solución
  completa o parte de la solución, sin saltarse datos).
- `t0_sol`: fecha a la que corresponde el primer día de
  `sol_vec`. Se espera que sea anterior a la fecha `t0`
  de `LossData`.
# Consideraciones
Se espera que la cantidad de datos sea consistente con
LossData; específicamente, que al calcular la fecha
final de la solución, esta coincida con el parámetro
`tf` de `LossData`. Por ejemplo, si la solución se
calculó con parámetro `tspan = (0.0,2.0)`, esto sumado al
`saveat = 1.0` nos da un total de 3 datos. Luego, si
`t0_sol = Date(2020,3,1)`, el día final de la solución
será `Date(2020,3,3)` (un dato por cada día). Entonces,
se espera que LossData haya sido creado con parámetro
`tf = Date(2020,3,3)`.
"""
=#

######### Incorporar los datos ##########

function estado_nI(sol)
  φₑᵢ = sol.prob.p.phi_ei
  -  φₑᵢ * nuevos_diarios(sol, index_susc())
end

function estado_cI(sol)
  φₑᵢ = sol.prob.p.phi_ei
  S0 = sum(sol'[1, index_susc()])
  φₑᵢ * (S0 .- sum(sol'[:, index_susc()], dims = 2))
end

function estado_Hc(sol::DiffEqBase.DESolution)
  sum(sol'[:, index_uci()], dims = 2)
end

function estado_cHc(sol::DiffEqBase.DESolution)
  cumsum(estado_Hc(sol), dims = 1)
end

function estado_D(sol)
  sum(sol'[:, index_muertos()], dims = 2)
end


function loss(sol::DiffEqBase.DESolution, t0_sol::Date,
  lossCumUCI::LossData, lossCumRep::LossData, lossCumD::LossData; chi = 1.0 )
  is_failure(sol) && return Inf

  un_dia = Dates.Day(1)

  total = lossCumUCI(estado_cHc(sol), t0_sol) +
    chi * lossCumRep(estado_cI(sol), t0_sol) +
    lossCumD(estado_D(sol), t0_sol)
  total
end

################### Función de pérdida ########################
function acumulados_desde(TS::TimeArray; i0 = 1)
  cumsum(TS[i0:end], dims = 1)
end


t0_sol = Date(2020,3,17)
lossCumUCI = LossData(acumulados_desde(TS_UCI_RM, i0=15), t0_sol,
  dia_final_sol(sol_cuarentena, t0_sol))
lossCumRep = LossData(acumulados_desde(TS_reportados_RM,i0=30),
  t0_sol + Dates.Day(1), dia_final_sol(sol_cuarentena, t0_sol))
lossCumDEIS = LossData(acumulados_desde(TS_DEIS_RM,i0=20),
  t0_sol, dia_final_sol(sol_cuarentena, t0_sol))


loss_function_reducedRep(sol_cuarentena)

loss_function_reducedRep = (sol) -> loss(sol, t0_sol,
  lossCumUCI, lossCumRep, lossCumDEIS,
  chi = 0.05)


####################################################
### Optimizar los parámetros                     ###
### Requiere haber corrido run_model_and_plot.jl ###
####################################################
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

function update_initial_s0!(data_u0::MyDataArray, s0)
  data_u0.x.S = s0 * data_u0.total_por_clase
  data_u0
end



copy_data_u0 = copy(data_u0)
prob_generator = (prob,p) -> remake(prob,u0 = update_initial_condition!(copy_data_u0, p), p=(p0_model_cte, p0_lmbda_cte))
prob_generator_full = (prob,p) -> remake(prob,u0 = update_initial_condition!(copy_data_u0, p), p=(p[9:17],p[18:22]))

function prob_generator_s0_beta(prob, p)
  p_vec[11] = p[2]
  remake(prob, u0 = update_initial_s0!(copy_data_u0, p[1]), p = (p_vec[1:9], p_vec[10:14]))
end

function prob_gen_onlyopt(prob,p)
  s0 = p[1]
  β = p[2]

  φₑᵢ = 0.5; φᵢᵣ = 0.85; φₕᵣ = 0.85; φ_d = 0.1;
  pᵢ = 0.75; pᵢₘ = 0.75pᵢ; pₑ = 0.5pᵢₘ
  p_model = ModelParam(p[3], p[4], p[5], p[6], p[7], φₑᵢ, φᵢᵣ, φₕᵣ, φ_d, LambdaParam(1.0, β, pₑ, pᵢ , pᵢₘ))

  remake(prob, u0 = update_initial_s0!(copy_data_u0, s0), p = p_model)
end

saveat = 1.0
cost_function = build_loss_objective(prob_cuarentena,Tsit5(),
  loss_function, prob_generator = prob_generator,
  saveat = saveat,
  maxiters = 10000
  )

cost_function_full = build_loss_objective(prob_cuarentena,Tsit5(),
  loss_function, prob_generator = prob_generator_full,
  saveat = saveat,
  maxiters = 10000
  )

cost_function_full_reducedRep = build_loss_objective(prob_cuarentena,Tsit5(),
  loss_function_reducedRep, prob_generator = prob_generator_full,
  saveat = saveat,
  maxiters = 10000
  )


cost_function_s0_beta = build_loss_objective(prob_cuarentena,Tsit5(),
  loss_function, prob_generator = prob_generator_s0_beta,
  saveat = saveat,
  maxiters = 10000
  )

cost_function_onlyopt = build_loss_objective(prob_cuarentena,Tsit5(),
  loss_function_reducedRep, prob_generator = prob_gen_onlyopt,
  saveat = saveat,
  maxiters = 10000
  )

cost_function_full(p0)
cost_function_full(p_10kiter)



#s0 = 0.9; e0 = 0.02; i0 = 0.02; im0 = 0.01; r0 = 0.02; h0 = 0.01; hc0=0.01; d0=0.01;
#u0_params = [s0, e0, i0, im0, r0, h0, hc0, d0]
#sum(u0_params)
lower_u0 = [0., 0., 0., 0., 0., 0., 0., 0.]
upper_u0 = [0.9, 0.01, 0.01, 0.01, 0.01, 0.01, 0.001, 0.]

#const p0_model_cte = p0_model
#p0_model =    [γₑ,    γᵢ,   γᵢₘ,  γₕ,    γₕ_c,  φₑᵢ, φᵢᵣ, φₕᵣ, φ_d]
lower_model = [1/6,  1/14, 1/14,  1/10,  1/16] #, 0.5, 0.85, 0.85, 0.1]
upper_model = [1/4,   1/7,  1/7,   1/2,  1/7] #  0.5, 0.85, 0.85, 0.1]

#const p0_lmbda_cte = p0_lmbda
#p0_lmbda = [1.0, β, pₑ, 1.0, pᵢₘ] saqué el alfa!
lower_lmbda = [0.1, 0.0, 0.6, 0.6]
upper_lmbda = [6.0, 0.2, 0.9, 0.9]


#p0 = [u0_params;p0_model; p0_lmbda]
lower = [0.3; 0.001; lower_model]
upper = [0.9; 1.0; upper_model]

prob_ini = prob_generator_full(prob_cuarentena, (lower + upper)/2)
sol_ini = solve(prob_ini, saveat = 1.0)
plot_comparar_datos(sol_ini, t0_sol)

cost_function_onlyopt(upper)

using BlackBoxOptim
#=
bboptimize(cost_function; SearchRange = (i -> (lower_u0[i], upper_u0[i])).(1:8))
p_res = [0.0981235, 0.000751838, 4.38449e-5, 0.000295247, 0.117949, 0.000234054, 2.25681e-5, 0.0352279]

res_full = bboptimize(cost_function_full; SearchRange = (i -> (lower[i], upper[i])).(1:22))


p0 = [0.9, 0.02, 0.02, 0.01, 0.02, 0.01, 0.01, 0.01, 0.14, 0.1, 0.1, 0.14285714285714285, 0.5, 0.1, 0.9, 0.6, 0.9, 1.0, 3.0, 0.2, 1.0, 0.4]
p_10kiter = [0.100961, 0.00440102, 0.0613713, 0.0991362, 0.508734, 0.726285, 0.000135861, 0.608562, 0.0100703, 3.82787, 3.98219, 0.0182238, 0.0705907, 0.280078, 0.745378, 0.999952, 0.00671096, 0.722137, 0.970178, 0.929587, 0.96598, 0.00962657]

p_10kiter_3 = [0.217294, 0.00686224, 0.000444803, 0.0239579, 0.626459, 0.00069024, 5.84598e-5, 0.672834, 0.157914, 0.0100634, 2.02298, 3.26838, 0.522249, 0.819409, 0.0840141, 0.982569, 0.0216682, 0.897604, 1.06372, 0.0873241, 0.937055, 0.0838925]

p_50kiter = [0.0969546, 0.146413, 1.09846e-5, 0.104801, 0.297526, 0.00555738, 1.22076e-6, 0.0309135, 0.0103015, 0.0101211, 0.656864, 0.369947, 1.14764, 0.290392, 0.0103027, 0.98965, 0.00207951, 0.521254, 4.79618, 7.40387e-6, 0.944759, 7.03487e-5]
=#
### Problema Full parametros, Loss iguales
opt_pro_full = bbsetup(cost_function_full; SearchRange = (i -> (lower[i], upper[i])).(1:22));
res_full = bboptimize(opt_pro_full, MaxSteps=5000000)
prob_full_opt = prob_generator_full(prob_cuarentena,res_full.archive_output.best_candidate)
sol_full = solve(prob_full_opt, saveat =saveat)

### Problema Full parametros, Loss reducida en los Reportados
opt_pro_onlyopt = bbsetup(cost_function_onlyopt; SearchRange = (i -> (lower[i], upper[i])).(1:7));
res_onlyopt = bboptimize(opt_pro_onlyopt, MaxSteps=5000000)
prob_onlyopt = prob_generator_full(prob_cuarentena, res_onlyopt.archive_output.best_candidate)
sol_onlyopt = solve(prob_onlyopt, saveat =saveat)
plot_comparar_datos(sol_onlyopt, t0_sol)

cost_function_onlyopt(res_onlyopt.archive_output.best_candidate)





plot_comparar_datos(sol_full, t0_sol)

opt_prob_full_gener = bbsetup(cost_function_full; SearchRange = (i -> (lower[i], upper[i])).(1:22), Method =:generating_set_search);
res_full_gener = bboptimize(opt_prob_full_gener, MaxSteps=200000)

cost_function_full(res_fill4.archive_output.best_candidate)

p_10k_gener = [0.0287414, 8.31944e-26, 0.000388631, 1.25754e-16, 0.0176723, 0.00199379, 1.41772e-10, 2.53519e-9, 0.281396, 0.0279864, 1.3495, 0.575322, 0.01, 1.0, 0.12842, 0.974443, 0.507331, 0.549677, 4.65751, 0.00500003, 0.532661, 7.36203e-9]

cost_function_full(res_full_gener.archive_output.best_candidate)
cost_function_full()

index_u0 = 1:8
index_gamma = 9:13
index_phi = 14:17
index_alpha = 18:22

opt_pro_full





opt_s0_beta = bbsetup(cost_function_s0_beta; SearchRange = [(0.0, 1.0), (0.5, 4.0)]);
res_s0_beta = bboptimize(opt_s0_beta, MaxSteps=50000)
# =  [0.02650813261750469, 0.5010702132371551]

prob_s0_beta = prob_generator_s0_beta(prob_cuarentena, res_s0_beta.archive_output.best_candidate)
sol_s0_beta = solve(prob_s0_beta, saveat =saveat)

prob_ini = prob_generator(prob_cuarentena,p0)
sol_ini = solve(prob_ini, saveat = 1.0)

prob_50k = prob_generator(prob_cuarentena,p_50kiter)
sol_50k = solve(prob_50k, saveat = 1.0)

prob_resfill4 = prob_generator(prob_cuarentena, res_fill4.archive_output.best_candidate)
sol_resfill4 = solve(prob_resfill4, saveat = 1.0)

prob_gener = prob_generator(prob_cuarentena, res_full_gener.archive_output.best_candidate)
sol_gener = solve(prob_gener, saveat = 1.0)

print(res_full_gener.archive_output.best_candidate)

p_gener = [0.0016233880895019758, 0.0014560426461227216, 0.002695611021011668, 0.005891249636233385, 0.008012558241855715, 0.0005643108873903802, 4.64952732283368e-5, 0.0, 0.23660428119075572, 0.08866641324664376, 0.07786495396239039, 0.2082699816055291, 0.12582845530006798, 0.5, 0.85, 0.85, 0.1, 1.0, 3.1928371973424357, 0.06336951985614743, 0.6132876228791938, 0.8900988065779023]
p_best = [0.028741048756619758, 8.319443102913642e-26, 0.0003886312559776601,1.2575447716878036e-16, 0.01766911514249089, 0.0019937916020055235,1.417716281902779e-10, 2.5351876597414255e-9,0.28139815114150907, 0.027985470987121543, 1.3507202467432848, 0.5753223814862858, 0.01, 1.0, 0.12861420208153174, 0.9744416072835304, 0.5073026067651816, 0.5496774516044536, 4.657507908020234, 0.005091244271707155, 0.5326610561546619, 5.724623617612596e-7]


p_gener[8]

cost_function_full(p_best)

plot_comparar_datos(sol_ini)
plot_comparar_datos(sol_50k)
plot_comparar_datos(sol_gener)
plot_comparar_datos(sol_resfill4)

plot(sol_res)

prob_gener.u0.x.E

using Plots
scatter(preparar_para_comparar_UCI(TS_UCI_RM, t0, t1))




plot2 = plot(fechas_sol, preparar_para_comparar_UCI(sol_cuarentena, t0,t1), title = "UCI" )

TS_UCI_SS_RM

plot(TS_UCI_SS_RM[colnames(TS_UCI_SS_RM)[1:6]],
  labels = ["SS Central"  "SS Norte" "SS Occidente" "SS Oriente" "SS Sur" "SS Sur Oriente"],
  title = "VMI c19 confirmados"
)


plot( timestamp(TS_UCI_SS_RM),
  sum(values(TS_UCI_SS_RM[colnames(TS_UCI_SS_RM)[1:6]]), dims = 2),
  title = "Comparación datos UCI",
  label =  "DP48 - Total VMI C19 confirmados RM"
)

plot!( timestamp(TS_UCI_RM),
  sum(values(TS_UCI_RM), dims = 2),
  label = "DP8 - Pacientes COVID-19 en UCI RM"
)

plot!( timestamp(TS_UCI_Vis),
  sum(values(TS_UCI_Vis), dims = 2),
  label = "Visualizador - Pacientes COVID-19 UCI a nivel regional RM",
  linestyle = :dash
)



sum(values(TS_UCI_RM[colnames(TS_UCI_RM)[1:6]]), dims = 2)[1]
sum(values(TS_UCI_RM[colnames(TS_UCI_RM)[7:12]]), dims = 2)[1]

plot1 = plot_comparar_datos(sol_full, t0_sol)


plot_comparar_datos(sol_cuarentena, t0_sol, scale = :log10)



function plot_comparar_datos(sol, t0_sol; scale = :identity)
  fechas_sol = t0_sol:Dates.Day(1):dia_final_sol(sol, t0_sol)

  plot1 = plot(fechas_sol, estado_cI(sol), title = "Reportados", yscale = scale)
  scatter!(plot1, lossCumRep.dias, lossCumRep.data)

  plot2 = plot(fechas_sol, estado_cHc(sol), title = "UCI", yscale = scale)
  scatter!(plot2, lossCumUCI.dias, lossCumUCI.data)

  plot3 = plot(fechas_sol[2:end], estado_D(sol)[2:end], title = "Fallecidos acumulados", yscale = scale)
  scatter!(plot3,lossCumDEIS.dias, lossCumDEIS.data)

  plot(plot1, plot2, plot3, layout = (1,3))
end

t0_sol
plot_comparar_datos(sol_full, t0_sol)


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
