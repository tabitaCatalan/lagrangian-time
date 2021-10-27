#=
Validación de los parámetros del modelo
=#

using Plots

plot(TS_edad_sexo, color = [:mediumpurple1 :seagreen1 :purple3 :seagreen3 :purple4 :seagreen4])
colnames(TS_edad_sexo)

:MJoven
:FJoven
:MAdulto
:FAdulto
:MMayor
:FMayor

plot( acumulados_desde(TS_reportados))

function acumulados_desde(TS::TimeArray; i0 = 1)
    cumsum(TS[i0:end], dims = 1)
end

function plot_sum_clase!(a_plot, TS::TimeArray, index_clase, label)
    scatter!(a_plot,timestamp(TS), sum(values(TS)[:,index_clase], dims = 2), label = label, msw = 0, ms = 2)
end

cumTS_rep = cumsum(TS_reportados, dims = 1)
rep_RM_del_total = (cumTS_rep[Symbol("Metropolitana")] ./ cumTS_rep[Symbol("Total")])[2:end]
rep_RM_del_total = cumTS_rep[Symbol("Total")]
plot(cumTS_rep, legend = :topleft)
plot(sum(TS_GE, dims = 2))

plot_edad = plot(title = "Casos por edad")
plot_sum_clase!(plot_edad, TS_edad_sexo, 1:2, "0-24 años")
plot_sum_clase!(plot_edad, TS_edad_sexo, 3:4, "25-64 años")
plot_sum_clase!(plot_edad, TS_edad_sexo, 5:6, "65 años o más")

plot_sexo = plot(title = "Casos por sexo")
plot_sum_clase!(plot_sexo, TS_edad_sexo, 1:2:5, "Hombre")
plot_sum_clase!(plot_sexo, TS_edad_sexo, 2:2:6, "Mujer")

plot_todos = plot(title = "Todos los casos")
plot_sum_clase!(plot_todos, TS_edad_sexo, 1:6, :none)

plot(title = "Total casos")
plot!(cumTS_rep[Symbol("Total")])
plot!(sum(TS_GE, dims = 2), label = "Suma GE")

