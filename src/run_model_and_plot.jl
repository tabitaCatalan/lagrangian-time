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
P_mov_reducida = reducir_movilidad(P_normal)

joven, adulto, mayor = index_edad()
hombre, mujer = index_sexo()
clase_baja, clase_media, clase_alta = index_clases()

n_clases = length(nombre_clases)
m_ambientes = length(nombre_ambientes)

u0 = set_up_inicial_conditions(total_por_clase)

a = 0.5; beta = 1.5; nu = 0.14; phi = 0.4; gi = 0.55; gm = 0.55;
p1 = set_up_parameters(a, beta, nu, phi, gi, gm, P_normal)
p2 = set_up_parameters(a, beta, nu, phi, gi, gm, P_mov_reducida)

tspan = (0.0,200.0)

output_folder = "../img/SEIIRplots-diferentes_params/casos_interesantes/"
filename = make_filename(a, beta, nu, phi, gi, gm)

### Resolver
prob1 = ODEProblem(seiir!,u0,tspan,p1)
sol1 = solve(prob1, saveat = 1.)
prob2 = remake(prob1; p = p2)
sol2 = solve(prob2, saveat = 1.)

s,e,im,i,r = index_estados(n_clases)

## Graficar
##########################
### Incidencia por grupos
##########################
# Se grafica la cantidad de infectados (estado = i) en función del tiempo, normalizado por la
# cantidad de personas en el grupo. Se guardan los gráficos (en .png).

plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia por nvl socioeconómico\n al reducir movilidad",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = total_por_clase,
    estado = i
)
savefig(output_folder*"incidenc_x_nvlsocio"*filename)

plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (hombre, mujer),
    incidencia_por_clase;
    title = "Cambio en la incidencia por sexo\n al reducir movilidad",
    labels_grupos = ["Hombre" "Mujer"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"incidenc_x_sexo"*filename)


plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia por edad\n al reducir movilidad",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"incidenc_x_edad"*filename)

##########################
### Infectados por grupos
##########################
# Se grafica la cantidad de infectados (estado = i) en función del tiempo.

plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (clase_baja, clase_media, clase_alta),
    total_estado_por_clase;
    title = "Cambio en los infectados por nvl socioeconómico\n al reducir movilidad",
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
