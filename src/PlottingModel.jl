#=
Este archivo contiene funciones para generar plots interesantes a partir de
soluciones de `EpidemicModel.jl`.
=#

using Plots

"""
    plot_comparesols_grouping_and_save(sols, index_grupos, labels_grupos, title, filename)
Compara varias soluciones, sumando los estados por grupo, y graficando los grupos
de la primera solucion en colores más intensos. Guarda la solucion.
# Argumentos
- `sols`: array o tupla de soluciones a ODEProblem, ordenadas de la mas a la menos importante.
    La más importante se graficará con colores más intensos, y las siguientes con la misma
    paleta de colores, pero cada vez más transparentes.
- `index_grupos`: array o tupla.
    `index_grupos[k]` contiene los índices de los estados de la solucion del grupo `k`.
- `labels_grupos`: array de String
    Nombre de cada uno de los grupos.
- `title`: String
    Título de gráfico
- `filename`: String
    Directorio y nombre del archivo donde se guarda la imagen, incluyendo extensión.
# Ejemplos
```julia
plot_comparesols_grouping_and_save(
    (sol1, sol2), # dos soluciones obtenidas con DifferentialEquations.solve
    (i[joven], i[adulto], i[mayor]), # índices de infectados jóvenes, adultos y mayores.
    ["Jóvenes", "Adultos", "Adulto Mayor"],
    "Cambio en los Infectados al reducir movilidad, por edad.",
    "../img/comparar_infectados_edad".png"
)
```
"""
function plot_comparesols_grouping_and_save(sols, index_grupos, labels_grupos, title, filename)
    min_alpha = 0.3
    max_alpha = 1.0
    L = length(sols)
    slope = (min_alpha - max_alpha)/(L-1)
    plot(title=title)
    for k in 1:length(index_grupos)
        for l in L:-1:2
            plot!(sols[l].t, sum(sols[l]'[:, index_grupos[k]], dims = 2), color = k, alpha = 0.4, label = :none)
        end
        plot!(sols[1].t, sum(sols[1]'[:, index_grupos[k]], dims = 2), color = k, label = labels_grupos[k])
    end
    savefig(filename)
end


"""
    plot_compare_function_of_sols_grouping(sols, index_grupos, a_function;
        labels_grupos, title="", kwargs...)

Compara varias soluciones, sumando los estados por grupo, y graficando los grupos
de la primera solucion en colores más intensos. Guarda la solucion.
# Argumentos
- `sols`: array o tupla de soluciones a ODEProblem, ordenadas de la menos a la más
    importante. Todas las soluciones se graficarán con la misma paleta de colores,
    pero la más importante tendrá colores más intensos, y las otras serán más
    transparentes.
- `index_grupos`: array o tupla de arrays o UnitRange
    `index_grupos[k]` contiene los índices asociados al grupo `k`-ésimo.
- `a_function`: function (callable)
    Una funcion de la solucion y los índices de los grupos, con la firma:
    `a_function(sol,index_grupo; kwargs...)`, donde
    - `sol`: una solución a ODEProblem
    - `index_grupo`: array o UnitRange de los índices asociados a un grupo.
    Debe devolver un Array del mismo largo que `sol.t`.
- `labels_grupos`: array de String
    Nombre de cada uno de los grupos.
- `title`: String (opcional)
    Título de gráfico.
- `kwargs...`: parámetros extra que se pasan a la función `a_function`.
# Ejemplos
```julia
plot_compare_function_of_sols_grouping(
    (sol1, sol2),
    (clase_baja, clase_media, clase_alta), # índices de clases jóvenes, adultos y mayores.
    incidencia_por_clase;
    labels_grupos = ["Nvl. bajo" "Nvl. medio" "Nvl. alto"],
    title = "Cambio en la incidencia, por nvl socioeconómico",
    total_por_clase = total_por_clase # requerido por incidencia_por_clase
)
```
"""
function plot_compare_function_of_sols_grouping(sols, index_grupos, a_function; labels_grupos, title="", kwargs...)
    L = length(sols)
    a_plot = plot(title=title)
    for k in 1:length(index_grupos)
        for l in 1:L-1
            α = calcular_alpha(l,L)
            plot!(a_plot, sols[l].t, a_function(sols[l],index_grupos[k]; kwargs...), color = k, alpha = α, label = :none)
        end
        plot!(a_plot, sols[end].t,  a_function(sols[end],index_grupos[k]; kwargs...), color = k, label = labels_grupos[k])
    end
    return a_plot
end

"""
    calcular_alpha(l, L)
Función auxiliar de `plot_compare_function_of_sols_grouping`. Entrega un valor
entre 0 y 1, que puede usarse como transparencia para graficar la solución actual
`l`-ésima, de un total de `L` soluciones. La intensidad del color va aumentando,
hasta alcanzar su máximo cuando `l = L`.
- `l`: solución actual, número entero entre 1 y L.
- `L`: total de soluciones
"""
function calcular_alpha(l, L)
    min_alpha = 0.3
    max_alpha = 1.0
    slope = (max_alpha-min_alpha)/(L-1)
    return slope*(l-1) + min_alpha
end

function incidencia_por_clase(sol, index_clase; estado, total_por_clase)
    return sum(sol'[:, estado[index_clase]], dims = 2)/sum(total_por_clase[index_clase])
end

function total_estado_por_clase(sol, index_clase; estado = 1:18)
    return sum(sol'[:, estado[index_clase]], dims = 2)
end


"""
    plot_all_states_and_save(sol; indexs = 1:18)
Hace una figura, graficando por separado cada estado (S, E, I, etc) c/r al tiempo.
Por defecto se grafica para todas las clases.
# Argumentos:
- `sol`: solucion a una ecuación diferencial, usando DifferentialEquations.solve.
- `n_clases`: numero total de clases consideradas en el modelo
- `filename::String`: archivo de salida, incluyendo el directorio y formato
    (`.png`, `.pdf`, etc).
- `indexs`: opcional, por defecto 1:18.
Indices de las clases que quieren graficarse. Deben ser valores entre 1 y n_clases.
# Ejemplos:
```julia
# supongo que sol es la salida de DifferentialEquations.solve
plot_all_states_and_save(sol, 18, "../img/all_states.png";indexs = 1:18)
```
"""
function plot_all_states_and_save(sol, n_clases, filename;indexs = 1:18)

    s, e, im, i, r = index_estados(n_clases)
    estados = index_estados(n_clases)

    l2 = @layout [grid(2,3) a{0.18w}]
    p = plot(
        plot(sol, vars = (0,s[indexs]), title = "Susceptibles", label = false),
        plot(sol, vars = (0,e[indexs]), title = "Expuestos", legend = false),
        plot(sol, vars = (0,im[indexs]), title = "No Reportados Iᵐ", legend = :none),
        plot(sol, vars = (0,i[indexs]), title = "Reportados I", legend = false),
        plot(sol, vars = (0,r[indexs]), title = "Removidos", legend = false),
        #plot(sol, vars = (0,d), title = "Muertos", legend = false),
        plot(),
        plot(sol, vars = (0,s[indexs]), label = nombre_clases, grid = false, showaxis = false, xlim = (-10,-1), xlabel = ""),
        #plot(sol, vars = (0,s), bar_position=:stack, label=nombre_clases, grid=false, showaxis=false),
        layout = l2, size=(600,400)
    )
    savefig(p, filename)
end

"""
    plot_nuevos_contagios(sol, filename)

"""
function plot_nuevos_contagios(sol, filename)
    s, = index_estados(n_clases)
    p = plot(
        plot(sol.t[2:end], sol'[1:end-1, s] - sol'[2:end, s],
            title = "Nuevos contagios",
            #label = nombre_clases,
            xlabel = "t"),
        plot(sol.t[2:end], sum(sol'[1:end-1, s] - sol'[2:end, s], dims = 2),
            title = "Total nuevos contagios", xlabel = "t", legend=:none),
        layout = (1,2), size=(800,400)
    )
    savefig(p, filename)
end

"""
    index_estados(n_clases)
Devuelve una tupla con los índices asociados a cada uno de los estados del modelo.
# Ejemplos
```julia
julia> s, e, im, i, r = index_estados(3)
(1:3, 4:6, 7:9, 10:12, 13:15)
```
"""
function index_estados(n_clases)
    s = 1:n_clases
    e = n_clases+1:2*n_clases
    im = 2*n_clases+1:3*n_clases
    i = 3*n_clases+1:4*n_clases
    r = 4*n_clases+1:5*n_clases
    s, e, im, i, r
end

"""
    nombre_estados()
Devuelve una lista de 5 strings, con los nombres de los estados del modelo.
"""
function nombre_estados()
    return [ "Susceptibles", "Expuestos", "No Reportados Iᵐ", "Reportados I", "Removidos"]
end
