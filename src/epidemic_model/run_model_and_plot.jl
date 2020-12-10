#=
Este script carga los archivos `EpidemicModel.jl` y `PlottingModel.jl`.
Resuelve un modelo epidemiológico y grafica los resultados.
=#

cd(@__DIR__)
# cd("src") # descomentar si hay error al incluir los archivos

include("MatrixP.jl")
include("ReadCuarentenaData.jl")
include("EpidemicModel.jl")
include("PlottingModel.jl")

begin
    P_normal, total_por_clase, nombre_ambientes, nombre_clases = read_matlab_data("..\\..\\results\\Pdata.mat")
    suma_uno_por_fila!(P_normal)

    δ = calcular_delta(P_normal)

    P_cuarentena = copy(P_normal)
    aplicar_cuarentena!(P_cuarentena)

    P_con_clases = copy(P_normal)
    teletrabajo!(P_con_clases, δ)

    P_trabajo_normal = copy(P_normal)
    cerrar_colegios!(P_trabajo_normal, δ)
end

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
    354167, 342032, 629593, 602701, 273074, 264804,
    500720, 509142, 897487, 948986, 492673, 530052,
    92717, 124998, 142013, 199701, 79823, 128125
]

total_por_clase = total_por_clase_censo/10

u0 = set_up_inicial_conditions(total_por_clase)

###########################################
######## Datos Cuarentenas ################
###########################################
csv_cuarentena = "..\\..\\data\\CuarentenasRMv2.csv"
eod_db = "..\\..\\data\\EOD2012-Santiago.db"
pobla_query = "..\\epidemic_model\\query-poblacion-clase.sql"

frac_cuarentena, dias_cuarentena = obtener_frac_cuarentena_from_csv(
    csv_cuarentena, eod_db, pobla_query,
    delim = ',', tramos = true, modo = :cuarentena
)
numero_dias = length(frac_cuarentena)
csv_paso_a_paso = "..\\..\\data\\paso_a_paso_por_comunas.csv"
frac_PaP, dias_PaP = obtener_frac_cuarentena_from_csv(
    csv_paso_a_paso, eod_db, pobla_query, tramos = true,
    delim = ',', modo = :PaP
);

frac_outbreak = [frac_cuarentena; frac_PaP]
dias_outbreak = [dias_cuarentena; dias_PaP];
#TS_frac = TimeArray(times_frac, frac, [:T1, :T2, :T3])

plot(frac_outbreak)


fecha0 = Date(2020, 3, 17)
index0 = findfirst(isequal(fecha0), dias_outbreak)

data_u0 = MyDataArray{Float64}(u0, P_normal, P_cuarentena, frac_outbreak[index0:end,:], total_por_clase_censo)
t_final = size(frac_outbreak)[1] - index0

#############################################
# Definir parametros
#############################################
s,e,im,i,r, h, hc, d = index_estados(n_clases)
output_folder = "..\\..\\img\\SEIIRHHD\\"
extension = ".svg"

begin
    pᵢ = 0.75; pᵢₘ = 0.1125; pₑ = pᵢₘ/2; β = 3.5;
    lambda_param = LambdaParam(1.0, β, pₑ, 1.0, pᵢₘ)

    dias = 10
    γₑ = 1/5; γᵢ = 1/dias; γᵢₘ = 1/dias;
    γₕ = 1/6; γₕ_c = 1/10;
    φₑᵢ = 0.5; φᵢᵣ = 0.85; φₕᵣ = 0.85; φ_d = 0.1
    p = ModelParam(γₑ, γᵢ, γᵢₘ, γₕ, γₕ_c, φₑᵢ, φᵢᵣ, φₕᵣ, φ_d, lambda_param)
    p_vec = [γₑ, γᵢ, γᵢₘ, γₕ, γₕ_c, φₑᵢ, φᵢᵣ, φₕᵣ, φ_d, 1.0, β, pₑ, 1.0, pᵢₘ]
    tspan = (0.0,t_final)
    #τ = 100. # tiempo de implementar medidas


    #=
    p2 = set_up_parameters(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ,P_cuarentena)
    p3 = set_up_parameters2(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena, P_normal)
    p4 = set_up_parameters2(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena, P_trabajo_normal)
    p5 = set_up_parameters2(αₑ, αᵢₘ, β, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena, P_con_clases)
    p6 = set_up_parameters3(αₑ, αᵢₘ, β, β₂, γₑ, φ, γᵢ, γᵢₘ, τ,P_cuarentena)
    =#
    filename = make_filename(p)
end
### Resolver
save_at = 1.

prob_cuarentena = ODEProblem(seiirhhd!,data_u0,tspan,make_model_param(p_vec))
sol_cuarentena = solve(prob_cuarentena, saveat = save_at);

plot_total_all_states(sol_cuarentena)

size(sol_cuarentena')
size(frac)
a = 1

#=
plot_comparar_datos(sol_cuarentena)
plot_all_states(sol_cuarentena, n_clases, nombre_clases; indexs = joven)
plot_comparar_datos(sol_cuarentena)

prob_normal = ODEProblem(seiirhhd!,data_u0,tspan,p_vec)
sol_normal = solve(prob_normal, saveat = save_at);

a = 1

prob_cuarentena = remake(prob_normal; p = p2)
sol_cuarentena = solve(prob_cuarentena, saveat = save_at)
=#


#plot_all_states(sol_normal, n_clases, nombre_clases; indexs = joven)


#plot_all_states(sol_cuarentena, n_clases, nombre_clases; indexs = joven)


#=
prob_retormar_normalidad = ODEProblem(seiir_Pt!, u0, tspan, p3)
sol_retormar_normalidad = solve(prob_retormar_normalidad, saveat = save_at)
prob_retomar_trabajo = remake(prob_retormar_normalidad; p = p4)
sol_retormar_trabajo = solve(prob_retomar_trabajo, saveat = save_at)
prob_retomar_clases = remake(prob_retomar_trabajo; p = p5)
sol_retormar_clases = solve(prob_retomar_clases, saveat = save_at)

prob_eliminar_mascarillas = ODEProblem(seiir_beta_t!, u0, tspan, p6)
sol_eliminar_mascarillas = solve(prob_eliminar_mascarillas, saveat = save_at)



plot(title = "Desfase Expuestos")
plot!(sol_cuarentena, vars = (0,[e[1], i[1]]))

## Graficar
##########################
### Total nuevos contagios
##########################

plot_all_states(sol_retormar_normalidad, n_clases, nombre_clases; indexs = clase_baja)
plot_all_states(sol_retormar_clases, n_clases, nombre_clases; indexs = clase_baja)
plot_all_states(sol_eliminar_mascarillas, n_clases, nombre_clases; indexs = joven)


plot_nuevos_contagios(
    (sol_cuarentena, sol_retormar_clases, sol_retormar_trabajo, sol_eliminar_mascarillas),
    n_clases,
    labels = ["Cuarentena siempre" "Retomar clases en t=$τ" "Vuelta al trabajo en t=$τ" "Eliminar mascarillas en t=$τ"];
    title = "Contagios diarios")
savefig(output_folder*"comparar_nuevos_contagios2456"*filename*extension)
=#
#=
plot_nuevos_contagios(
    [sol_normal, sol_cuarentena],
    n_clases,
    labels = ["Sin medidas preventivas" "Teletrabajo y cierre de centros educativos "];
    title = "Contagios diarios")
plot!(legend=:topright)
savefig(output_folder*filename*extension)


a = 1;=#
#=

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_trabajo),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia por nvl socioeconómico\n al restablecer trabajo en t=$τ",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = total_por_clase,
    estado = i
)
savefig(output_folder*"retorno_trabajo_nvlsocio"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_trabajo),
    (hombre, mujer),
    incidencia_por_clase;
    title = "Cambio en la incidencia por sexo\n al restablecer trabajo en t=$τ",
    labels_grupos = ["Hombre" "Mujer"],
    total_por_clase = total_por_clase,
    estado = i
)
savefig(output_folder*"retorno_trabajo_sexo"*filename*extension)


plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_retormar_clases),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia por edad\n al retomar clases en t=$τ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"retorno_clases"*filename*extension)


plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas en el tranporte público en t=$τ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-tp-edad"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas al comprar desde t=$τ",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-compras-nvl"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (hombre, mujer),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas al comprar desde t=$τ",
    labels_grupos = ["Hombre" "Mujer"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-compras-sexo"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas al comprar desde t=$τ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-compras-edad"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas en el transporte público desde t=$τ",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-tp-nvl"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (hombre, mujer),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas en el transporte público desde t=$τ",
    labels_grupos = ["Hombre" "Mujer"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-tp-sexo"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_cuarentena, sol_eliminar_mascarillas),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia al dejar de usar\n mascarillas en el transporte público t=$τ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"mascarillas-tp-edad"*filename*extension)




##########################
### Incidencia por grupos
##########################
# Se grafica la cantidad de infectados (estado = i) en función del tiempo, normalizado por la
# cantidad de personas en el grupo. Se guardan los gráficos (en .png).

plot_compare_function_of_sols_grouping(
    (sol_normal, sol_cuarentena),
    (clase_baja, clase_media, clase_alta),
    incidencia_por_clase;
    title = "Cambio en la incidencia por nvl socioeconómico\n ",
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    total_por_clase = total_por_clase,
    estado = i
)
savefig(output_folder*"incidenc_x_nvlsocio12"*filename*extension)

plot_compare_function_of_sols_grouping(
    (sol_normal, sol_cuarentena),
    (hombre, mujer),
    incidencia_por_clase;
    title = "Cambio en la incidencia por sexo\n ",
    labels_grupos = ["Hombre" "Mujer"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"incidenc_x_sexo12"*filename*extension)


plot_compare_function_of_sols_grouping(
    (sol_normal, sol_cuarentena),
    (joven, adulto, mayor),
    incidencia_por_clase;
    title = "Cambio en la incidencia por edad\n ",
    labels_grupos = ["Joven" "Adulto" "Mayor"],
    estado = i,
    total_por_clase = total_por_clase
)
savefig(output_folder*"incidenc_x_edad12"*filename*extension)




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
