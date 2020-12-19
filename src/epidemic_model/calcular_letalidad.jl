#=
Estimar letalidad por grupo de edad
Usé esto
https://www.trt.net.tr/espanol/photogallery/infografia/la-tasa-de-mortalidad-del-coronavirus-por-edades
=#

include("utils.jl")


edades = 1:90
letalidad = ones(90)
letalidad[1:9] .= 0.0
letalidad[10:39] .= 0.2
letalidad[40:49] .= 0.4
letalidad[50:59] .= 1.3
letalidad[60:69] .= 3.6
letalidad[70:79] .= 8.0
letalidad[80:90] .= 14.0

a,b = linear_regression(edades[10:end], log.(letalidad[10:end]))

letalidad_covid(edad) = exp(-3.296361752014349) * exp(0.06785587268228627 * edad)

pobla_grupos_edad_RM = [467643, 469789, 440294, 492924, 595721, 642862, 559323, 507128, 488623, 462874, 470878, 418848, 328524, 250864, 197598, 136396, 90536, 59915, 23613, 6484, 1971]
index_grupo_edad = i -> 5*(i-1):(5*i -1)


letalidades = Vector{Float64}(undef,3)

grupos_edades = (1:5, 6:13, 14:21)
for i in 1:3
  edades = grupos_edades[i]
  letalidad_total = 0
  for j in edades
    index_grupo = index_grupo_edad(j)
    letalidad_grupo = sum(letalidad_covid.(index_grupo))/5
    letalidad_total += letalidad_grupo * pobla_grupos_edad_RM[j]
  end
  letalidades[i] = letalidad_total./sum(pobla_grupos_edad_RM[edades])
end

letalidad_v2 = ones(90)
letalidad_v2[1:24] .= letalidades[1]
letalidad_v2[25:64] .= letalidades[2]
letalidad_v2[65:end] .= letalidades[3]

edades = 1:90

using Plots
plot(edades, letalidad, label = "Datos mortalidad")
plot!(edades, letalidad_covid.(edades), label = "Mortalidad aproximada")
plot!(edades, letalidad_v2, label = "Morlidad aproximada por tramo", legend = :topleft)
