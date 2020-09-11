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
        plot!(sols[1].t, sum(sols[1]'[:, index_grupos[k]], dims = 2), color = k, label = labels_grupos[k])
    end
    savefig(filename)
end

"""
    plot_all_states_and_save(sol; indexs = 1:18)
Hace una figura, graficando por separado cada estado (S, E, I, etc) c/r al tiempo.
Por defecto se grafica para todas las clases.
# Argumentos:
- `sol`: solucion a una ecuación diferencial, usando DifferentialEquations.solve.
- `indexs`: opcional, por defecto 1:18.
Indices de las clases que quieren graficarse. Deben ser valores entre 1 y n_clases.
"""
function plot_all_states_and_save(sol, n_clases, filename;indexs = 1:18)
    estados = index_estados
    l2 = @layout [grid(2,3) a{0.18w}]
    plot2 = plot(
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
    savefig(plot2, filename)
end

"""
    index_estados(n_clases)
Devuelve una tupla con los índices asociados a cada uno de los estados del modelo.
# Ejemplos
```julia
julia> index_estados(3)
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

