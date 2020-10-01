#=
Este script carga los archivos `EpidemicModel.jl` y `PlottingModel.jl`.
Resuelve un modelo epidemiológico y grafica los resultados.
=#

cd(@__DIR__)
# cd("src") # descomentar si hay error al incluir los archivos

include("EpidemicModel.jl")
include("PlottingModel.jl")


P_normal, total_por_clase, nombre_ambientes, nombre_clases = read_matlab_data("..\\results\\Pdata.mat")
suma_uno_por_fila!(P_normal)
δ = calcular_delta(P_normal)

P_cuarentena = copy(P_normal)
aplicar_cuarentena!(P_cuarentena)

P_con_clases = copy(P_normal)
teletrabajo!(P_con_clases, δ)

P_trabajo_normal = copy(P_normal)
cerrar_colegios!(P_trabajo_normal, δ)


joven, adulto, mayor = index_edad()
hombre, mujer = index_sexo()
clase_baja, clase_media, clase_alta = index_clases()

n_clases = length(nombre_clases)
m_ambientes = length(nombre_ambientes)

"""
    total_por_clase_censo
rango_ips   rango_edad  n_hombres   n_mujeres
1           1           354167      342032
1           2	        500720	    509142
1           3       	92717	    124998
2	        1	        629593	    602701
2	        2	        897487	    948986
2	        3	        142013   	199701
3	        1           273074   	264804
3	        2	        492673   	530052
3	        3	        79823   	128125
"""
total_por_clase_censo = [
    354167,
    342032,
    629593,
    602701,
    273074,
    264804,
    500720,
    509142,
    897487,
    948986,
    492673,
    530052,
    92717,
    124998,
    142013,
    199701,
    79823,
    128125
]

total_por_clase = total_por_clase_censo

u0 = set_up_inicial_conditions(total_por_clase)

#αᵢₘ = 0.15; αₑ = aᵢₘ/2
αᵢₘ = 0.7; αₑ = αᵢₘ/2; β = 1.2; γₑ = 0.14; φ = 0.4;
γᵢ = 0.3; γᵢₘ = 0.3;
τ = 400. # tiempo de implementar medidas

s,e,im,i,r = index_estados(n_clases)

p1 = set_up_parameters(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, P_normal)
p2 = set_up_parameters(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ,P_cuarentena)
p3 = set_up_parameters2(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena, P_normal)
p4 = set_up_parameters2(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena, P_trabajo_normal)
p5 = set_up_parameters2(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena, P_con_clases)

tspan = (0.0,600.0)

output_folder = "../img/SEIIR-P_ips/"
filename = make_filename(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ)

### Resolver
prob1 = ODEProblem(seiir!,u0,tspan,p1)
sol1 = solve(prob1, saveat = 1.)
prob_cuarentena = remake(prob1; p = p2)
sol_cuarentena = solve(prob_cuarentena, saveat = 1.)

prob_retormar_normalidad = ODEProblem(seiir_Pt!, u0, tspan, p3)
sol_retormar_normalidad = solve(prob_retormar_normalidad, saveat = 5.)
prob_retomar_trabajo = remake(prob_retormar_normalidad; p = p4)
sol_retormar_trabajo = solve(prob_retomar_trabajo, saveat = 5.)
prob_retomar_clases = remake(prob_retomar_trabajo; p = p5)
sol_retormar_clases = solve(prob_retomar_clases, saveat = 5.)



## Graficar
##########################
### Total nuevos contagios
##########################

plot_all_states(sol_cuarentena, n_clases, nombre_clases; indexs = joven)
plot_all_states(sol_retormar_normalidad, n_clases, nombre_clases; indexs = clase_baja)
plot_all_states(sol_retormar_clases, n_clases, nombre_clases; indexs = clase_baja)



plot_nuevos_contagios(
    (sol_cuarentena, sol_retormar_normalidad, sol_retormar_clases, sol_retormar_trabajo),
    n_clases,
    labels = ["Cuarentena siempre" "Vuelta a normalidad en t=$τ" "Retomar clases en t=$τ" "Vuelta al trabajo en t=$τ"];
    title = "Contagios diarios")
savefig(output_folder*"comparar_nuevos_contagios2345"*filename)


plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_trabajo),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia por nvl socioeconómico\n al restablecer trabajo en t=$τ",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = total_por_clase,
    estado = i
)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_clases),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia por nvl socioeconómico\n al restablecer clases en t=$τ",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = total_por_clase,
    estado = i
)


plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_clases),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia por edad\n al retomar clases en t=$τ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_trabajo),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia por edad\n al retomar trabajo en t=$τ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)



##########################
### Incidencia por grupos
##########################
# Se grafica la cantidad de infectados (estado = i) en función del tiempo, normalizado por la
# cantidad de personas en el grupo. Se guardan los gráficos (en .png).

plot_compare_function_of_sols_grouping(
    (sol1, sol3),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia por nvl socioeconómico\n al restablecer movilidad en t=200",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = total_por_clase,
    estado = i
)
savefig(output_folder*"incidenc_x_nvlsocio13"*filename)

plot_compare_function_of_sols_grouping(
    (sol1, sol3),
    (hombre, mujer),
    incidencia_por_clase;
    title = "Cambio en la incidencia por sexo\n al restablecer movilidad en t=200",
    labels_grupos = ["Hombre" "Mujer"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"incidenc_x_sexo13"*filename)


plot_compare_function_of_sols_grouping(
    (sol1, sol2, sol3),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia por edad\n al restablecer movilidad en t=200",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"incidenc_x_edad123"*filename)

##########################
### Infectados por grupos
##########################
# Se grafica la cantidad de infectados (estado = i) en función del tiempo.

plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (clase_baja, clase_media, clase_alta),
    total_estado_por_clase;
    title = "Cambio en los infectados por nvl socioeconómico\n al restablecer movilidad en t=200",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    estado = i
)


plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (joven, adulto, mayor),
    total_estado_por_clase;
    title = "Cambio en los infectados por edad\n al reducir movilidad",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i
)

plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (hombre, mujer),
    total_estado_por_clase;
    title = "Cambio en los infectados por sexo\n al reducir movilidad",
    labels_grupos = ["Hombre" "Mujer"],
    estado = i
)




###########################
### Cambio en los infectados
##########################
# Se grafica la cantidad de infectados (estado = i) en función del tiempo.
plot_compare_function_of_sols_grouping( # Oh, funciona. Quien lo diría xD
    (sol1, sol2),
    1:18,
    total_estado_por_clase;
    title = "Cambio en los infectados por nvl socioeconómico\n al reducir movilidad",
    labels_grupos = nombre_clases,
    estado = i
)

plot_all_states(sol1, n_clases, nombre_clases;indexs = clase_baja)
plot_all_states(sol2, n_clases, nombre_clases;indexs = clase_baja)


plot_nuevos_contagios(sol2, nombre_clases)
#=
plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (joven, adulto, mayor),
    total_estado_por_clase;
    labels_grupos = ["Jóvenes", "Adultos", "Adulto Mayor"],
    title = "Cambio en la incidencia por edad al reducir movilidad.",
    estado = i
)

plot_comparesols_grouping_and_save(
    (sol1, sol2),
    (i[clase_baja], i[clase_media], i[clase_alta]),
    ["Nivel bajo", "Nivel medio", "Nivel alto"],
    "Cambio en los Infectados al reducir movilidad, \npor nvl socioeconómico.",
    output_folder * "I_nvlsocio_pobla-igual_mov-normvsreducid$filename.png"
)

plot_comparesols_grouping_and_save(
    (sol1, sol2),
    (i[hombre], i[mujer]),
    ["Hombre", "Mujer"],
    "Cambio en los Infectados al reducir movilidad, por sexo.",
    output_folder * "I_sexo_pobla-igual_mov-normvsreducid$filename.png"
)

plot_comparesols_grouping_and_save(
    (sol1, sol2, sol3, sol4),
    (i[clase_baja], i[clase_media], i[clase_alta]),
    ["Nivel bajo", "Nivel medio", "Nivel alto"],
    "Cambio en los Infectados al aumentar clase alta, \npor nvl socioeconómico.",
    output_folder * "Inormvsplus_nvlsocio_mov_reducidad$filename.pdf"
)

plot_comparesols_grouping_and_save(
    (sol1, sol2, sol3, sol4),
    i,
    nombre_clases,
    "Cambio en los Infectados al aumentar clase alta, \npor nvl socioeconómico.",
    output_folder * "prueba$filename.png"
)

plot_comparesols_grouping_and_save(
    (sol1, sol2),
    (i[clase_baja], i[clase_media], i[clase_alta]),
    ["Nivel bajo", "Nivel medio", "Nivel alto"],
    "Cambio en la incidencia, \npor nvl socioeconómico.",
    output_folder * "prueba$filename.png"
)
=#
