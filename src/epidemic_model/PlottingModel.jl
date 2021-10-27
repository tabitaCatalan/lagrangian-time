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
function plot_compare_function_of_sols_grouping(sols, index_grupos, a_function; labels_grupos, title="", dias = sols[1].t, scale = :identity, kwargs...)
    L = length(sols)
    a_plot = plot(title=title)
    for k in 1:length(index_grupos)
        for l in 1:L-1
            α = calcular_alpha(l,L)
            plot!(a_plot, dias, a_function(sols[l],index_grupos[k]; kwargs...), color = k, alpha = α, label = :none)
        end
        plot!(a_plot, dias,  a_function(sols[end],index_grupos[k]; kwargs...), color = k, label = labels_grupos[k], yscale = scale)
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
    return 1e5 .* sum(sol'[:, estado[index_clase]], dims = 2)/sum(sol.prob.u0.total_por_clase[index_clase])
end



function total_estado_por_clase(sol, index_clase; estado = 1:18)
    return sum(sol'[:, estado[index_clase]], dims = 2)
end


function plot_total_all_states(sols, t0_sol; index_clase = 1:18, estados = index_estados_seiirhhcd(18), nombres = nombre_estados_seiirhhcd())
    plots = []
    n_dias = size(sols[1]')[1]
    fechas  = t0_sol:Dates.Day(1):(t0_sol + Dates.Day(n_dias - 1))
    for i in 1:length(estados)
            a_plot = plot(title = nombres[i])
        for sol in sols
            plot!(a_plot, fechas,
                total_estado_por_clase(sol, index_clase, estado = estados[i]),
                label = :none
            )
        end
        push!(plots, a_plot)
    end
    plot(plots...)
end

"""
    plot_all_states(sol, n_clases, nombre_clases ;indexs = 1:n_clases)
Hace una figura, graficando por separado cada estado (S, E, I, etc) c/r al tiempo.
Por defecto se grafica para todas las clases.
# Argumentos:
- `sol`: solucion a una ecuación diferencial, usando DifferentialEquations.solve.
- `n_clases`: numero total de clases consideradas en el modelo
- `nombre_clases`: vector de largo `n_clases` con los nombres de todas las clases.
- `indexs`: opcional, por defecto 1:18.
Indices de las clases que quieren graficarse. Deben ser valores entre 1 y n_clases.
# Ejemplos:
```julia
# supongo que sol es la salida de DifferentialEquations.solve
plot_all_states(sol, 5, ["c1" "c2" "c2" "c4" "c5"]; indexs = 3:5)
```
"""
function plot_all_states(sol, n_clases, nombre_clases;indexs = 1:n_clases)
    s, e, im, i, r = index_estados(n_clases)
    #estados = index_estados(n_clases)
    labels = reshape(nombre_clases[indexs], (1,length(indexs)))
    l2 = @layout [grid(2,3) a{0.18w}]
    p = plot(
        plot(sol, vars = (0,s[indexs]), title = "Susceptibles", label = false),
        plot(sol, vars = (0,e[indexs]), title = "Expuestos", legend = false),
        plot(sol, vars = (0,im[indexs]), title = "No Reportados Iᵐ", legend = :none),
        plot(sol, vars = (0,i[indexs]), title = "Reportados I", legend = false),
        plot(sol, vars = (0,r[indexs]), title = "Removidos", legend = false),
        #plot(sol, vars = (0,d), title = "Muertos", legend = false),
        plot(),
        plot(sol, vars = (0,s[indexs]), label = labels, grid = false, showaxis = false, xlim = (-10,-1), xlabel = ""),
        #plot(sol, vars = (0,s), bar_position=:stack, label=nombre_clases, grid=false, showaxis=false),
        layout = l2, size=(600,400)
    )
    return p
    #savefig(p, filename)
end

"""
    plot_nuevos_contagios(sol, filename)
Compara la cantidad de nuevos contagios diarios para varias soluciones.
Opcionalmente, es posible hacerlo solo para un subconjunto de clases sociales.
# Argumentos
- `sols`: tupla o array de soluciones ODEProblem
- `n_clases`: int
    Cantidad de clases sociales del modelo
- `labels`: (opcional) lista de los nombres de cada solución
- `index_grupo`: UnitRange o Array (opcional)
    Índices indicando las clases a considerar. Por defecto serán todas (1:`n_clases`).
- `title`: (opcional) título del gráfico
"""
function plot_nuevos_contagios(sols, n_clases; labels = ["Solución $i" for i in 1:n_clases], index_grupo = 1:n_clases, title = "")
    a_plot = plot(title = title, legend = :topleft)
    for i in 1:length(sols)
        plot!(a_plot, sols[i].t[2:end],
            nuevos_contagios(sols[i], n_clases, index_grupo),
            label = labels[i]
        )
    end
    a_plot
end

function nuevos_contagios(sol, n_clases, index_grupo)
    s = 1:n_clases
    sum(sol'[1:end-1, s[index_grupo]] - sol'[2:end, s[index_grupo]], dims = 2)
end

"""
    index_estados(n_clases)
Devuelve una tupla con los índices asociados a cada uno de los estados del modelo.
# Ejemplos
```julia
julia> s, e, im, i, r, h, hc, d = index_estados(3)
(1:3, 4:6, 7:9, 10:12, 13:15, 16:18, 19:21, 22:24)
```
"""
function index_estados_seiirhhcd(n_clases)
    s = 1:n_clases
    e = n_clases+1:2*n_clases
    im = 2*n_clases+1:3*n_clases
    i = 3*n_clases+1:4*n_clases
    r = 4*n_clases+1:5*n_clases
    h = 5*n_clases+1:6*n_clases
    hc = 6*n_clases+1:7*n_clases
    d = 7*n_clases+1:8*n_clases
    s, e, im, i, r,h, hc, d
end

function index_estados_seii(n_clases)
    s = 1:n_clases
    e = n_clases+1:2*n_clases
    i = 2*n_clases+1:3*n_clases
    im = 3*n_clases+1:4*n_clases
    ci = 4*n_clases+1:5*n_clases
    s, e, i, im, ci
end

"""
    nombre_estados_seiirhhcd()
Devuelve una lista de 8 strings, con los nombres de los estados del modelo.
"""
function nombre_estados_seiirhhcd()
    return [ "Susceptibles", "Expuestos", "No Reportados Iᵐ", "Reportados I", "Removidos", "Hospitalizados", "UCI", "Muertos"]
end
