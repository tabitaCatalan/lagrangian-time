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
index_cumrep(;n_clases = 18) = rango_estado(5, n_clases)
#index_uci(;n_clases = 18) = rango_estado(7, n_clases)
#index_muertos(;n_clases = 18) = rango_estado(8, n_clases)

##### Preparar solución y datos para comparar #####
"""
  nuevos_diarios(sol, estado; index_grupo = 1:18)
Calcula para un estado la diferencia entre el número de personas entre un día
y el anterior.
"""
function nuevos_diarios(sol::DiffEqBase.DESolution, estado; index_grupo = 1:18)
    sum(sol'[2:end, estado[index_grupo]] - sol'[1:end-1, estado[index_grupo]], dims = 2)
end

function nuevos_diarios(acumulados)
    acumulados[2:end] - acumulados[1:end-1]
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

function drop_missing_and_vectorize(array2)
  L = length(array2)
  vector = Vector{Float64}(undef, L)
  for l in 1:L
    vector[l] = Float64(array2[l])
  end
  vector
end

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

  function LossData(dias::Vector{Date}, data::Vector{T}, data0::T, t0_sol::Date, tf_sol::Date; cumulative::Bool) where {T<:Real}
    if length(data) != length(dias)
      error("Los vectores `dias` y `data` deben ser del mismo largo.")
    end
    index_en_rango = index_dias_entre_t0_y_tf(dias, t0_sol, tf_sol)

    t0 = dias[index_en_rango[1]]
    tf = dias[index_en_rango[end]]

    full_dias = collect(t0:Dates.Day(1):tf)
    full_index = collect(1:length(full_dias))
    index_dias = full_index[is_in(full_dias, dias)]

    if cumulative
      data0 += 0.0 #sum(data[1:index_en_rango[1]-1])
    end

    new{Date,T,eltype(index_dias)}(t0,tf,dias[index_en_rango],data0 .+ data[index_en_rango],index_dias)
  end
end

##### Constructor externo ######
function LossData(TS::TimeArray, t0_sol::Date, tf_sol::Date; data0 = 0.0, cumulative = false)
  dias = timestamp(TS)
  data = drop_missing_and_vectorize(suma_por_fila_y_filtrar_fecha(TS, dias[1],dias[end]))

  LossData(dias,data, data0, t0_sol, tf_sol, cumulative = cumulative)
end

function dia_final_sol(sol::DiffEqBase.DESolution, t0_sol::Date)
  n_dias = Integer(sol.t[end] - sol.t[1]) + 1
  tf_sol = t0_sol + Dates.Day(n_dias - 1)
  tf_sol
end


function (f::LossData)(sol_vec, t0_sol::Date)
  index_comparable = f.index_dias .+ cuantos_dias(t0_sol, f.t0)
  #sum(abs.(sol_vec[index_comparable] - f.data))
  sum((log.(sol_vec[index_comparable]) - log.(f.data)).^2)
end

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

function estado_cI(sol::DiffEqBase.DESolution; clase = 1:18)
  #φₑᵢ = sol.prob.p.phi_ei
  #S0 = sum(sol'[1, index_susc()])
  #φₑᵢ * (S0 .- sum(sol'[:, (index_susc())[clase] ], dims = 2))
  sum(sol'[:,(index_cumrep())[clase]], dims = 2)
end

function estado_nI(sol::DiffEqBase.DESolution; clase = 1:18)
  nuevos_diarios(sol, index_cumrep(), index_grupo = clase)
end
#=
function estado_Hc(sol::DiffEqBase.DESolution; clase = 1:18)
  sum(sol'[:, (index_uci())[clase]], dims = 2)
end

function estado_cHc(sol::DiffEqBase.DESolution; clase = 1:18)
  cumsum(estado_Hc(sol, clase = clase), dims = 1)
end

function estado_D(sol::DiffEqBase.DESolution; clase = 1:18)
  sum(sol'[:, (index_muertos())[clase] ], dims = 2)
end

function estado_nD(sol::DiffEqBase.DESolution; clase = 1:18)
  nuevos_diarios(sol, index_muertos(), index_grupo = clase)
end


function loss(sol::DiffEqBase.DESolution, t0_sol::Date,
  lossCumUCI::LossData, lossRep::LossData, lossCumRep::LossData, lossCumD::LossData; chi = 1.0 )
  is_failure(sol) && return Inf

  un_dia = Dates.Day(1)

  total = chi * lossRep(estado_nI(sol), t0_sol) + lossCumRep(estado_cI(sol), t0_sol)  +  lossCumUCI(estado_cHc(sol), t0_sol) + lossCumD(estado_D(sol), t0_sol)
  total
end
=#

function loss(sol::DiffEqBase.DESolution, t0_sol::Date, lossCumRep::LossData)
  is_failure(sol) && return Inf

  un_dia = Dates.Day(1)

  total = lossCumRep(estado_cI(sol), t0_sol)
  total
end

################### Función de pérdida ########################
function acumulados_desde(TS::TimeArray; i0 = 1)
  cumsum(TS, dims = 1)[i0:end]
end


t0_sol = Date(2020,3,14)
lossCumRep = LossData(acumulados_desde(TS_reportados_RM, i0 = 15), t0_sol + Dates.Day(1), dia_final_sol(sol, t0_sol), cumulative = true)
#lossRep = LossData(TS_reportados_RM[15:end], t0_sol + Dates.Day(1), dia_final_sol(sol_cuarentena, t0_sol))

ts[1]
plot(acumulados_desde(TS_reportados_RM)[1:50])
scatter!(lossCumRep.dias[1:30], lossCumRep.data[1:30])

#plot(lossRep.dias, lossRep.data)
#=
lossCumUCI = LossData(acumulados_desde(TS_UCI_RM), t0_sol,
  dia_final_sol(sol_cuarentena, t0_sol), data0 = )
lossCumDEIS = LossData(acumulados_desde(TS_DEIS_RM,i0=20),
  t0_sol, dia_final_sol(sol_cuarentena, t0_sol))
=#



loss_function_reducedRep = (sol) -> loss(sol, t0_sol, lossCumRep)

loss_function_reducedRep(sol)

#loss_function_reducedRep(sol_onlyopt)

#loss(sol_onlyopt, t0_sol, lossCumUCI, lossCumRep, lossCumDEIS)
#=
lossCumRep(estado_cI(sol_onlyopt), t0_sol)
lossCumUCI(estado_cHc(sol_onlyopt), t0_sol)
lossCumDEIS(estado_D(sol_onlyopt), t0_sol)=#
####################################################
### Optimizar los parámetros                     ###
### Requiere haber corrido run_model_and_plot.jl ###
####################################################
copy_data_u0 = copy(u0)

function update_u0!(data_u0, p::ModelParam, χ)
    n_clases = length(data_u0.total_por_clase)
    e0_total = χ[3]*χ[2]/(p.phi_ei * p.gamma_e)
    im0_total = e0_total * (1. - p.phi_ei)*p.gamma_e/(χ[2] + p.gamma_im)

    data_u0.x.E .= e0_total * data_u0.total_por_clase/sum(data_u0.total_por_clase)
    data_u0.x.I .= 0.0
    data_u0.x.Im .= im0_total * data_u0.total_por_clase/sum(data_u0.total_por_clase)
    data_u0.x.cI .= 0.0
    data_u0.x.S .= data_u0.total_por_clase - data_u0.x.E - data_u0.x.Im;
end



[0.16438183724824845, 0.05068548489679065, 0.4984372419195904, 0.19941277664013923, 0.21474378483263964, 0.32117105802944657, 0.7745266812338238, 0.3085262769176047, 0.04898519733784269, 0.14995717499177721] # gamas i iguales
function prob_gen_onlyopt(prob,p)
  #s0 = p[4] #p[10]

  γₑ = p[1] # 0.16670693884606166;
  γᵢ = p[2] #0.14285714285616494
  γᵢₘ =p[2] # 0.10896815031718815;
  γₕ = 0.135 #p[3] # 0.135109 # 0.10925543802432831;
  γₕ_c = 0.1 #p[4] # 0.14285628589518273;

  φₑᵢ = 0.5;
  φᵢᵣ = 0.85;
  φₕᵣ = 0.85;
  φ_d = 0.2;

  α = p[3]
  β = p[3]#p[7] #0.048425295377355446;
  pᵢ = 0.75; pᵢₘ = 0.75pᵢ; pₑ = 0.5pᵢₘ
  τ = p[4]

  p_model = ModelParam(γₑ, γᵢ, γᵢₘ, γₕ, γₕ_c, φₑᵢ, φᵢᵣ, φₕᵣ, φ_d, LambdaParam(α, β, pₑ, pᵢ , pᵢₘ), τ)
  χ = (385.63261209545453, 0.05770318779090708, 777.5140235716095)
  #prob.u0.total_por_clase .= s0 * total_por_clase_censo
  update_u0!(prob.u0, p_model, χ)
  remake(prob, p = p_model)
end

cost_function_onlyopt_5 = build_loss_objective(prob_3,Tsit5(),
  loss_function_reducedRep, prob_generator = prob_gen_onlyopt,
  saveat = 1.0,
  maxiters = 10000
  )

using NLopt

#lower = [1/25, 1/20, 0.04, 50.0]
#upper = [1/5, 1/5, 0.08, 130.0]



cost(x) = x[1]^2 - x[2]
lower = [-3.,-6.]
upper = [6., 8.]


a_plot = plot(title = "Comparación")
scatter_loss!(a_plot, lossCumRep, nuevos = true)

cost_function_onlyopt(lower)

optx

#lower_gamma = [1/20, 1/14, 1/14, 1/10, 1/15]
#upper_gamma = [1/4, 1/7,  1/7,  1/2,  1/10]
#             [γₑ,  γᵢ =  γᵢₘ,  γₕ,   γₕ_c]
lower_gamma = [1/20, 1/20] # 1/10, 1/25]
upper_gamma = [1/4, 1/5] #  1/5,  1/5]
#           [φₑᵢ, φᵢᵣ,  φₕᵣ,  φ_d]
lower_phi = [0.4] #, 0.3, 0.3,  0.02]
upper_phi = [0.6]#, 0.8, 0.8, 0.8]

#############################################################
### Problema solo param a optim, Loss reducida en los Reportados
############################################################
#p0_model =     φₑᵢ=0.4, φᵢᵣ, φₕᵣ, φ_d]
#lower_model = [1/6,  1/14, 1/14,  1/10,  1/16, 0.75, 0.7, 0.05]
#upper_model = [1/4,   1/7,  1/7,   1/2,  1/7, 0.95, 0.95, 0.2]


Ns = 11



#=
opt = Opt(:GN_DIRECT_L, 3)
opt.min_objective = cost_function_onlyopt
opt.lower_bounds = lower
opt.upper_bounds = upper
(optf,optx,ret) = NLopt.optimize(opt, (upper + lower)/2)
=#
collect(0.1:0.1:1.0)

s0s = 0.1:0.1:1.0
Ns = length(s0s)
#res_x = Array{Float64,2}(undef,Ns,3)
#res_f = Vector{Float64}(undef,Ns)
#for i in 1:Ns
s0 = 1.0
data_u0.total_por_clase .= s0 * total_por_clase_censo
update_u0!(data_u0, p, χ)


1/optx[2]
optx[5]
#res_f[i] = optf
#res_x[i,:] = optx
#end

res_f
res_x
[1 ./res_x[:,1] 1 ./res_x[:,2]]

cost_function_onlyopt(optx_2)
ret
function linspace(ini, fin, steps)
  h = (fin - ini)/steps
  ini:h:fin
end
beta = 0.05
beta < upper[3]

lower[1]
upper[1]

best = [0.0666772, 0.052039, 0.0751813, 0.0300008]
best = [0.0666701, 0.0538363, 0.0753577, 0.0203948]
best = [0.04474026684863652, 0.08503568901051466, 0.07710260395313509, 0.010061280225618025]
optx = [0.06756594649904933, 0.1994088548461781, 0.07046334028726406, 0.0327397961308488, 66.37543309581625]



xs = linspace(lower[1],upper[1], 10)
ys = linspace(lower[2],upper[2], 10)
zs = [cost_function_onlyopt([x,y,0.05]) for y in ys, x in xs]
surface(xs, ys, zs)
(upper)



function add_fecha_tau!(plot, prob; fechas = false)
  if fechas
    vline!(plot, [Date(2020, 3, 14) + Dates.Day(floor(Int, prob.p.tau))])
  else
    vline!(plot, [prob.p.tau], label = :none)
  end

end

optx[4]

sol_onlyopt_3'

sol_onlyopt'

frac_outbreak_5[end,:]

prob_onlyopt_3 = prob_gen_onlyopt(prob_3, optx)
sol_onlyopt_3  = solve(prob_onlyopt_3, saveat =1.0)
prob_onlyopt_4 = prob_gen_onlyopt(prob_4, optx)
sol_onlyopt_4  = solve(prob_onlyopt_4, saveat =1.0)
prob_onlyopt_5 = prob_gen_onlyopt(prob_5, optx)
sol_onlyopt_5  = solve(prob_onlyopt_5, saveat =1.0)

plot1 = plot_comparar_datos(sol, t0_sol)

for a_plot in plot1.subplots add_fecha_tau!(a_plot,prob, fechas = true) end
display(plot1)
sol_onlyopt_5'

plot2 = plot_total_all_states([sol_onlyopt_3, sol_onlyopt_4, sol_onlyopt_5], t0_sol, estados = index_estados_seii(18), nombres = nombre_estados_seii())

for a_plot in plot2.subplots add_fecha_tau!(a_plot,prob_onlyopt) end

savefig(plot1, output_folder * "rep_data" *  make_filename(prob.p) * extension)
savefig(plot2, output_folder * "all_states_proy" *  make_filename(prob_onlyopt.p) * extension)
output_folder
plot(plot1.subplots[1], yscale = :log10)



prob_onlyopt.tspan
prob_onlyopt_2 = remake(prob_onlyopt, tspan = (0.0, 300.))
sol_onlyopt_2  = solve(prob_onlyopt_2, saveat =1.0)
plot_comparar_datos(sol, t0_sol)
plot_total_all_states([sol], t0_sol, estados = index_estados_seii(18), nombres = nombre_estados_seii())

# Hay diferencias ahora al cambiar las fases? Puedo lograr ese mismo resultado con otro modelo? Seguramente.
# Pero puedo ver algo interesante en las clases sociales? En el nvl socioeconómico por ejemplo?


plot_total_all_states([sol], t0_sol, index_clase = clase_alta, estados = index_estados_seii(18), nombres = nombre_estados_seii())
plot_total_all_states([sol], t0_sol, index_clase = clase_media, estados = index_estados_seii(18), nombres = nombre_estados_seii())

# Graficar la incidencia para los tres...

MJoven = sum([594059, 618121,585855,636064,702706])
FJoven = sum([572087, 592068, 561560, 608633, 685116])
MAdulto = sum([742265, 645359, 595608,586674,562483,569852,499406,399562])
FAdulto = sum([731885, 648278, 612169, 611829, 598280, 615102, 548373, 447353])
MMayor = sum([303259, 232909, 155526, 94996, 53469, 18029, 4188, 1599])
FMayor = sum([349743, 283000, 208063, 144450, 98332, 40854, 11668, 3171])

pobla_nacional = [MJoven, FJoven, MAdulto, FAdulto, MMayor, FMayor]

TS_edad_sexo


socio_plot = plot_compare_function_of_sols_grouping(
    [sol],
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Incidencia por nvl socioeconómico\n",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = data_u0.total_por_clase,
    estado = index_cumrep(), dias = dias_outbreak[1:end-1]
)
savefig(socio_plot, output_folder * "incid_nvlsocio" *  filename * extension)

edad_plot = plot_compare_function_of_sols_grouping(
    [sol],
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Incidencia por edad",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    total_por_clase = data_u0.total_por_clase,
    estado = index_cumrep(), dias = dias_outbreak[1:end-1]
)
savefig(edad_plot, output_folder * "incid_edad" *  filename * extension)
sol_onlyopt'
dias_outbreak

plot!(socio_plot, yscale = :log10)

optx




p_test = [0.23245048012082883, 0.4989748918058404, 0.1000084160004651, 0.14740831186199518, 0.20000019801257227, 0.30000165666336853, 0.8649201746711364, 0.38444716687447594, 0.11489029390096843]
print(res_onlyopt_2.archive_output.best_candidate)
using Optim
#using NLopt
#inner_optimizer = GradientDescent()
#results = optimize(cost_function_onlyopt, lower, upper, p_best, Fminbox(inner_optimizer))
p_best = res_onlyopt_2.archive_output.best_candidate
print(p_best)
# 14285714285616494 p[2]
p_best_1 = [0.1461583260483094, 0.07142857143834559, 0.49146565416034527, 0.09999999999963989, 0.40000000000171626, 0.7500000000005304, 0.7000000000012518, 0.1999999999981954, 0.04999999999756714, 0.1313034048044971]
p_best_2 = [0.07142857155705251, 0.09883621089505033, 0.49756574289433786, 0.13268887536075566, 0.38000000000692887,  0.7000000015703264, 0.7000000015703264, 0.5239032162303336, 0.04999999997862783, 0.10432575973339672]
p_best_3 = [0.16438183724824845, 0.05068548489679065, 0.4984372419195904, 0.19941277664013923, 0.21474378483263964, 0.32117105802944657, 0.7745266812338238, 0.3085262769176047, 0.04898519733784269, 0.14995717499177721] # gamas i iguales
p_best_2


begin
  p_test = res_onlyopt_2.archive_output.best_candidate #[0.16438183724824845, 0.05068548489679065, 0.4984372419195904, 0.19941277664013923, 0.21474378483263964, 0.32117105802944657, 0.7745266812338238, 0.3085262769176047, 0.05] # gamas i iguales
  #p_test[2] = 0.03
  #p_test[2] =
  p_test[1] = 1/7
  p_test[3] = 0.3
  p_test[4] = 0.01

  prob_onlyopt = prob_gen_onlyopt(prob_cuarentena, p_test)
  sol_onlyopt  = solve(prob_onlyopt, saveat =1.0)
  #plot_comparar_datos(sol_onlyopt, t0_sol)
  plot_total_all_states(sol_onlyopt, modelo = :seii)

end

p_test[4]

function estado_cI(sol::DiffEqBase.DESolution; clase = 1:18)
  φₑᵢ = sol.prob.p.phi_ei
  S0 = sum(sol'[1, (index_susc())[clase]])
  φₑᵢ * (S0 .- sum(sol'[:, (index_susc())[clase] ], dims = 2))
end

plot(title = "Reportados acumulados por edad")
plot!(fechas_sol, estado_cI(sol_onlyopt, clase = 1:6), label = "Joven")
plot!(fechas_sol, estado_cI(sol_onlyopt, clase = 7:12), label = "Adulto")
plot!(fechas_sol, estado_cI(sol_onlyopt, clase = 13:18), label = "Mayor")

plot(title = "Fallecidos por edad")
plot!(fechas_sol[2:end], estado_nD(sol_onlyopt, clase = 1:6), label = "Joven")
plot!(fechas_sol[2:end], estado_nD(sol_onlyopt, clase = 7:12), label = "Adulto")
plot!(fechas_sol[2:end], estado_nD(sol_onlyopt, clase = 13:18), label = "Mayor")



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




a_plot = plot_comparar_datos(sol_onlyopt, t0_sol)

function scatter_loss!(a_plot, loss::LossData; error = 0.05, nuevos = false)
  if nuevos
    scatter!(a_plot, loss.dias[2:end], nuevos_diarios(loss.data), ribbon = nuevos_diarios(loss.data)*error, msw = 0, ms = 1)
  else
    scatter!(a_plot, loss.dias, loss.data, ribbon = loss.data*error, msw = 0, ms = 1)
  end
end

plot(title = "Reportados acumulados RM")
scatter!(lossCumRep.dias, lossCumRep.data, label = :none, msw = 0, ms = 2)
savefig(output_folder * "cumrep_RM.svg")

fechas_sol = t0_sol:Dates.Day(1):dia_final_sol(sol, t0_sol)
function plot_comparar_datos(sol, t0_sol; scale = :identity)
  fechas_sol = t0_sol:Dates.Day(1):dia_final_sol(sol, t0_sol)
  #fechas_sol = Dates.format.(fechas_sol, "dd/mm")

  plot1 = plot(fechas_sol, estado_cI(sol), title = "Reportados acumulados", yscale = scale)
  scatter_loss!(plot1, lossCumRep)

  plot1b = plot(fechas_sol[2:end], estado_nI(sol), title = "Reportados diarios", yscale = scale)
  scatter_loss!(plot1b, lossCumRep, nuevos = true)

  #plot2 = plot(fechas_sol, estado_cHc(sol), title = "UCI acumulados", yscale = scale)
  #scatter_loss!(plot2, lossCumUCI)

  #plot2b = plot(fechas_sol, estado_Hc(sol), title = "UCI diarios", yscale = scale)
  #scatter_loss!(plot2b, lossCumUCI, nuevos = true)

  #plot3 = plot(fechas_sol[2:end], estado_D(sol)[2:end], title = "Fallecidos acumulados", yscale = scale)
  #scatter_loss!(plot3, lossCumDEIS)

  #plot3b = plot(fechas_sol[2:end], estado_nD(sol), title = "Fallecidos diarios", yscale = scale)
  #scatter_loss!(plot3b, lossCumDEIS, nuevos = true)

  plot(plot1, plot1b, legend = :none)
end

scatter(lossCumDEIS.dias, lossCumDEIS.data, ribbon = lossCumDEIS.data*0.05, msw = 0, ms = 1)

plot_comparar_datos(sol, t0_sol)


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
