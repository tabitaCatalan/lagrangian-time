cd(@__DIR__)

## Importar dependencias
using MAT # leer archivos .mat
using ComponentArrays
using DifferentialEquations, Plots
using StaticArrays
using ImageMagick

"""
    read_matlab_data(mat_filename)
Leer datos obtenidos con Matlab.
# Argumentos
- `mat_filename::String`: nombre del archivo que contiene los datos generados
    por Matlab para trabajar con `n` clases y `m` ambientes. Debe incluir la
    extension `.mat`. Se espera que contenga cuatro variables:
    - `P`: matriz de tiempos de residencia, de `n` filas y `m` columnas.
        `P[i,j]` indica la fraccion de tiempo que la clase `i` pasa en el ambiente
        `j`. No necesariamente debe sumar 1 por fila (se normalizará después).
    - `total_por_clase`: vector de largo `n`, cantidad de individuos por clase.
    - `ambientes`: vector de largo `m`, nombre corto de los ambientes.
    - `nombres_clases`:  vector de largo `n`, nombre corto de las clases.
# Ejemplos
```julia
P, total_por_clase, nombre_ambientes, nombre_clases = read_matlab_data("../data/Pdata.mat")
```
"""
function read_matlab_data(mat_filename)
    Pdata = matopen(mat_filename)
    names(Pdata)
    P = read(Pdata, "P")
    total_por_clase = vec(read(Pdata, "total_por_clase"))
    nombre_ambientes = read(Pdata, "ambientes")
    nombre_clases = read(Pdata, "nombres_clases")
    close(Pdata)
    return P, total_por_clase, nombre_ambientes, nombre_clases
end

"""
    suma_uno_por_fila!(P)
Reescala los valores de P, para que sume 1 por fila.
# Ejemplos
```jldoctest
julia> suma_uno_por_fila!([0.2 0.5 0.1; 0.1 0.3 0.4])
2×3 Array{Float64,2}:
 0.25   0.625  0.125
 0.125  0.375  0.5
```
"""
function suma_uno_por_fila!(P)
    P ./= sum(P, dims = 2)
end

"""
    reducir_movilidad(P)
Reduce el tiempo invertido en los ambientes trabajo, estudios y transporte,
y lo traspasa al hogar.
El tiempo en el estudio se reduce en un 95% (no en un 100% para evitar que haya
inestabilidad al resolver la EDO).
El tiempo en el trabajo se reduce en un 20% para clase baja, 50% para clase media
y en un 80% para clase alta.
El tiempo en todos los medios de transporte se reduce en un 50%.
# Argumentos
- `P`: matriz de tiempos de residencia de clases vs ambientes. Supone lo sgte:
    - Hay 18 clases:
Indice | Clase
-------|-------
1      | Hombre clase baja joven
2      | Mujer clase baja joven
3      | Hombre clase media joven
4      | Mujer clase media joven
5      | Hombre clase alta joven
6      | Mujer clase alta joven
7      | Hombre clase baja adulto
8      | Mujer clase baja adulto
9      | Hombre clase media adulto
10     | Mujer clase media adulto
11     | Hombre clase alta adulto
12     | Mujer clase alta adulto
13     | Hombre clase baja mayor
14     | Mujer clase baja mayor
15     | Hombre clase media mayor
16     | Mujer clase media mayor
17     | Hombre clase alta mayor
18     | Mujer clase alta mayor
    - Hay 13 ambientes:
Indice | Ambiente
-------|----------
1      | Hogar
2      | Trabajo
3      | Estudios
4      | Compras
5      | Visitas
6      | Salud
7      | Tramites
8      | Recreo
9      | Transporte publico
10     | Auto
11     | Caminata
12     | Bicicleta
13     | Otro
"""
function reducir_movilidad(P)
    tpo_trabajo = P[:,2]
    clase_baja = [1 2 7 8 13 14]
    clase_media = clase_baja .+ 2
    clase_alta = clase_media .+ 2
    frac_reduccion = ones(18)
    frac_reduccion[clase_baja] .= 0.2
    frac_reduccion[clase_media] .= 0.5
    frac_reduccion[clase_alta] .= 0.8

    P2 = copy(P)
    P2[:,2] -= tpo_trabajo.*frac_reduccion
    P2[:,1] += tpo_trabajo.*frac_reduccion
    P2[:,1] += 0.95*P2[:,3]
    P2[:,3] *= 0.05
    transporte = 9:12
    P2[:,1] += sum(P2[:, transporte], dims = 2)/2.
    P2[:, transporte] /= 2.0

    return P2
end


"""
    index_clases()
Devuelve los indices asociados a las distintas clases socioeconómicas en la matriz P.
# Resultados
- `clase_baja`
- `clase_media`
- `clase_alta`
"""
function index_clases()
    clase_baja = [1 2 7 8 13 14]
    clase_media = clase_baja .+ 2
    clase_alta = clase_media .+ 2
    return clase_baja, clase_media, clase_alta
end


"""
    index_sexo()
Devuelve los indices asociados a los sexos en la matriz P.
# Resultados
- `masculino`
- `femenino`
"""
function index_sexo()
    masculino = 1:2:17
    femenino = 2:2:18
    return masculino, femenino
end

"""
    index_edad()
Devuelve los indices asociados a los distintos grupos de edad en la matriz P.
# Resultados
- `joven`
- `adulto`
- `mayor`
"""
function index_edad()
    joven = 1:6
    adulto = 7:12
    mayor = 13:18
    return joven, adulto, mayor
end
joven, adulto, mayor = index_edad()
hombre, mujer = index_sexo()
clase_baja, clase_media, clase_alta = index_clases()
P, total_por_clase, nombre_ambientes, nombre_clases = readp("../results/Pdata.mat")
suma_uno_por_fila!(P)
P2 = reducir_movilidad(P)
## Definir
nclases = length(nombre_clases)
nambientes = length(nombre_ambientes)

s = 1:nclases
e = nclases+1:2*nclases
im = 2*nclases+1:3*nclases
i = 3*nclases+1:4*nclases
r = 4*nclases+1:5*nclases



## Modelo SEIIR

"""
    seiir!(du,u,p,t)
Modelo epidemiológico tipo SEIIR
# Arguments
- `du`:
- `u`:
- `p`: tupla que contiene los sgtes parámetros
  - `β`: vector de riesgos por ambiente
  - `ν`: vector, tiene que ver con el tiempo de incubacion...
  - `φ`: fraccion de asintomaticos
  - `γ`: tasa de recuperacion asintomaticos
  - `γₘ`: tasa de recuperacion sintomaticos
- `t`:
"""
function seiir!(du,u::ComponentArray,p,t)
    α, β, ν, φ, γ, γₘ, P = p
    λ = P*((P'*(u.I + α*u.E + u.Im)).*β./(P'*(u.S + u.E + u.Im + u.I + u.R)))
    du.S  = -λ.*u.S
    du.E  = λ.*u.S - ν.*u.E
    du.I  = φ*ν.*u.E - γ.*u.I
    du.Im = (1.0 - φ).*ν.*u.E - γₘ .*u.Im
    du.R  = γₘ .*u.Im + γ.*u.I
end;


## Condiciones iniciales y parametros
e0 = 5.0*ones(nclases)
i0 = zeros(nclases)
im0 = zeros(nclases)
s0 = (total_por_clase - i0)
r0 = zeros(nclases)

u0 = ComponentArray(S = s0, E = e0, Im = im0, I = i0, R = r0)
tspan = (0.0,200.0)

#for beta in 0.5:1.0:1.5,  nu in 0.1:0.45:1.0 , gi in 0.1:0.45:1.0, gm in 0.1:0.45:1.0
#for  nu in 0.14:0.14 # el numero que usa navas
beta = 1.5
gi = 0.55
gm = 0.55
a = 0.5
phi = 0.4
nu = 0.14

output_folder = "../results/SEIIRplots-diferentes_params/casos_interesantes/"

filename = "_a$a _beta$beta _nu$nu _phiei$phi _gi$gi _gm$gm"
filename = replace(filename, " " => "")
filename = replace(filename, "." => "-")
println(filename)

β = beta*[0.1, 0.5, 0.7, 0.7, 0.5, 0.5, 0.7, 0.7, 1.0, 0.1, 0.4, 0.1, 0.1]
ν = nu*ones(nclases)
φ = phi
γ = gi*ones(nclases)
γₘ = gm*ones(nclases)
p1 = (a, β, ν, φ, γ, γₘ, P)
p2 = (a, β, ν, φ, γ, γₘ, P2)

#try
### Resolver
prob1 = ODEProblem(seiir!,u0,tspan,p1)
sol1 = solve(prob1, saveat = 1.)
prob2 = ODEProblem(seiir!,u0,tspan,p2)
sol2 = solve(prob2, saveat = 1.)


"""
    plot_comparesols_grouping_and_save(sols, index_grupos, labels_grupos, title, filename)
Compara dos soluciones, sumando los estados por grupo, y graficando los grupos
de la primera solucion en colores más intensos. Guarda la solucion.
# Argumentos
- `sols`: array o tupla de dos soluciones a ODEProblem
- `index_grupos`: array o tupla.
    `index_grupos[k]` contiene los indices de los estados de la solucion del grupo `k`.
- `labels_grupos`: array de String
    Nombre de cada uno de los grupos.
- `title`: String
    Título de gráfico
- `filename`: String
    Directorio y nombre del archivo donde se guarda la imagen.
"""
function plot_comparesols_grouping_and_save(sols, index_grupos, labels_grupos, title, filename)
    plot(title=title)
    for k in 1:length(index_grupos)
        plot!(sols[1].t, sum(sols[1]'[:, index_grupos[k]], dims = 2), color = k, alpha = 0.4, label = :none)
        plot!(sols[2].t, sum(sols[2]'[:, index_grupos[k]], dims = 2), color = k, label = labels_grupos[k])
    end
    savefig(filename)
end

plot_comparesols_grouping_and_save(
    (sol1, sol2),
    (i[joven], i[adulto], i[mayor]),
    ["Jóvenes", "Adultos", "Adulto Mayor"],
    "Infectados por edad, reduciendo movilidad",
    output_folder * "I_edad_mov_reducidad$filename.png"
)

plot_comparesols_grouping_and_save(
    (sol1, sol2),
    (i[clase_baja], i[clase_media], i[clase_alta]),
    ["Nivel bajo", "Nivel medio", "Nivel alto"],
    "Infectados por nivel socioeconómico, reduciendo movilidad",
    output_folder * "I_nvlsocio_mov_reducidad$filename.png"
)

sols = 1
#palette = get_color_palette(:gnuplot2, 18) #.colors.colors[1:5:86]
plot(title = "Susceptibles")
for k in s
    plot!(sol1, vars = (0,k), label =:none, alpha = 0.4, color = k)
    plot!(sol2, vars = (0,k), label = nombre_clases[k], color = k)
end
savefig("output/S$filename.png")

plot(title = "Expuestos")
for k in e
    plot!(sol1, vars = (0,k), label=:none, alpha = 0.4, color = k-18)
    plot!(sol2, vars = (0,k), label = nombre_clases[k-18], color = k-18)
end
savefig("output/E$filename.png")

plot(title = "No Reportados Iᵐ")
for k in im
    plot!(sol1, vars = (0,k), label = :none, alpha = 0.4, color = k-18*2)
    plot!(sol2, vars = (0,k), label = nombre_clases[k-18*2], color = k-18*2)
end
savefig("output/Im$filename.png")

plot(title = "Reportados I")
for k in i
    plot!(sol1, vars = (0,k), label = :none, alpha = 0.4, color = k-18*3)
    plot!(sol2, vars = (0,k), label = nombre_clases[k-18*3], color = k-18*3)
end
savefig("output/I$filename.png")

plot(title = "Removidos")
for k in r
    plot!(sol1, vars = (0,k), label = :none,  alpha = 0.4, color = k-18*4)
    plot!(sol2, vars = (0, k), label =  nombre_clases[k-18*4], color = k-18*4)
end
savefig("output/R$filename.png")

#plot(sol, vars = (0,d), title = "Muertos", legend = false),
plot(),
plot(sol, vars = (0,s), label = nombre_clases, grid = false, showaxis = false, xlim = (-10,-1), xlabel = ""),
#plot(sol, vars = (0,s), bar_position=:stack, label=nombre_clases, grid=false, showaxis=false),
layout = l2, size=(600,400)





### Graficar




l2 = @layout [grid(2,3) a{0.18w}]
p2 = plot(
    plot(sol, vars = (0,s), title = "Susceptibles", label = false),
    plot(sol, vars = (0,e), title = "Expuestos", legend = false),
    plot(sol, vars = (0,im), title = "No Reportados Iᵐ", legend = :none),
    plot(sol, vars = (0,i), title = "Reportados I", legend = false),
    plot(sol, vars = (0,r), title = "Removidos", legend = false),
    #plot(sol, vars = (0,d), title = "Muertos", legend = false),
    plot(),
    plot(sol, vars = (0,s), label = nombre_clases, grid = false, showaxis = false, xlim = (-10,-1), xlabel = ""),
    #plot(sol, vars = (0,s), bar_position=:stack, label=nombre_clases, grid=false, showaxis=false),
    layout = l2, size=(600,400)
)
savefig(p2, "output/estados_por_clase$filename.png")
# 1... 36... 54... 72... 90...108
p3 = plot(
    plot(sol.t, sum(sol'[:, s], dims = 2), legend=:none,
    title = "Susceptibles"),
    plot(sol.t, sum(sol'[:, e], dims = 2), legend=:none,
    title = "Expuestos"),
    plot(sol.t, sum(sol'[:, im], dims = 2), legend=:none,
    title = "No Reportados Iᵐ"),
    plot(sol.t, sum(sol'[:, i], dims = 2), legend=:none,
    title = "Reportados I"),
    plot(sol.t, sum(sol'[:, r], dims = 2), legend=:none,
    title = "Removidos"),
    #plot(sol.t, sum(sol'[:, d], dims = 2), legend=:none,
    #title = "Muertos"),
    plot(),
    layout = (2,3), size=(600,400)
)
savefig(p3, "output/estados_totales$filename.png")

p4 = plot(
    plot(sol.t[2:end], sol'[1:end-1, s] - sol'[2:end, s],
        title = "Nuevos contagios",
        label = nombre_clases, xlabel = "t"),
    plot(sol.t[2:end], sum(sol'[1:end-1, s] - sol'[2:end, s], dims = 2),
        title = "Total nuevos contagios", xlabel = "t", legend=:none),
    layout = (1,2), size=(800,400)
)
savefig(p4, "output/nuevos_contagios$filename.png")
#catch
#    println("No se pudo resolver para $filename")
#end
#end

function filename!(a, beta, nu, phi, gm , gi)

end


#gm = 0.1
#gi = 0.55
#nu = 0.1
#beta = 1.0
#phi = 0.4
filename = "a$a _phi$phi _nu$nu _beta$beta _gm$gm _gi$gi"
filename = replace(filename, " " => "")
filename = replace(filename, "." => "-")
println(filename)
plot(xlabel = "t")
#for a in 0.2:0.2:0.8
#β = beta*[0.1, 0.5, 0.7, 0.7, 0.5, 0.5, 0.7, 0.7, 1.0, 0.1, 0.4, 0.1, 0.1]
#ν = nu*ones(nclases)
#φ = phi
#γ = gi*ones(nclases)
#γₘ = gm*ones(nclases)
p = (a, β, ν, φ, γ, γₘ, P2)

### Resolver
prob = ODEProblem(seiir!,u0,tspan,p)
sol = solve(prob, saveat = 1.)

#plot!(sol.t, sum(sol'[:, im], dims = 2), label = "Im, φ=$phi", color = color, yaxis=:log)
#plot!(sol.t, sum(sol'[:, i], dims = 2), label = "I, φ=$phi", color = color, alpha = 0.8, yaxis=:log)

#global color += 1
plot!(sol.t[2:end], sum(sol'[1:end-1, s] - sol'[2:end, s], dims = 2),
    title = "Total nuevos contagios", label="Movilidad reducida")
#end

savefig("output/nuevos_contagios_movilidad$filename.png")
