#=
validar_matrix_P.jl
Validar la forma en que se está modificando la matriz P
=#



"""
    as_p100_variation(baseline, array_of_values)
Expresa un arreglo de valores como percentajes de variación con respecto al primer
valor del arreglo. `array_of_values[i]` es una variación del
`array_of_variations[i]`% de `baseline`.
# Ejemplo
```
julia> as_p100_variation(10.0, [10.0, 6.0, 2.0, 4.0, 12.0])
5-element Array{Float64,1}:
   0.0
 -40.0
 -80.0
 -60.0
  19.999999999999996
 ```
"""
function as_p100_variation(baseline, array_of_values)
    array_of_variations = 100*(array_of_values./baseline' .- 1)
    array_of_variations
end

function ambiente_en_el_tiempo(u::MyDataArray, ambientes, tspan; clase = 1:18)
    P = similar(u.P_normal)
    T = floor(Int,tspan[2] - tspan[1])
    serie = Vector{Float64}(undef, T)
    for t in 1:T
        P_t!(P, u::MyDataArray, t)
        tiempo_ambiente_t = sum(P[clase, ambientes])
        serie[t] = tiempo_ambiente_t
    end
    serie
end

function baseline_ambiente(u, ambiente; clase = 1:18)
    sum(P_normal_original[clase, ambiente])
end

function variacion_ambiente(u, ambiente, tspan; tramos = false)
    if tramos
        clase_baja, clase_media, clase_alta = index_clases()
        base = [baseline_ambiente(u, ambiente; clase = clase_baja),
                baseline_ambiente(u, ambiente; clase = clase_media),
                baseline_ambiente(u, ambiente; clase = clase_alta)]
        amb_t_T1 = ambiente_en_el_tiempo(u, ambiente, tspan; clase = clase_baja)
        amb_t_T2 = ambiente_en_el_tiempo(u, ambiente, tspan; clase = clase_media)
        amb_t_T3 = ambiente_en_el_tiempo(u, ambiente, tspan; clase = clase_alta)
        ambiente_t = [amb_t_T1 amb_t_T2 amb_t_T3]
    else
        base = baseline_ambiente(u, ambiente)
        ambiente_t = ambiente_en_el_tiempo(u, ambiente, tspan)
    end
    as_p100_variation(base, ambiente_t)
end

length(variacion_ambiente(data_u0, 3, tspan))
fechas_sol = t0_sol:Dates.Day(1):(dia_final_sol(sol_cuarentena, t0_sol) - Dates.Day(1))

#fechas_sol = Dates.format.(fechas_sol, "dd/mm")
length(fechas_sol)

index_transporte() = 9:12

begin
    ambientes_plot = plot(title = "Variación transporte")

    plot!(ambientes_plot,  fechas_sol,
        variacion_ambiente(data_u0, index_transporte(), tspan, tramos = true),
        label = ["Trans nvl bajo" "Trans nvl medio" "Trans nvl alto"]
    )

end


begin
    ambientes_plot = plot(title = "Variación ambientes")
    #=
    plot!(ambientes_plot, fechas_sol,
        variacion_ambiente(data_u0, index_transporte(), tspan),
        label = "Medios de transporte"
    )=#


    plot!(ambientes_plot,  fechas_sol,
        variacion_ambiente(data_u0, 9, tspan),
        label = "TP"
    )

    plot!(ambientes_plot,  fechas_sol,
        variacion_ambiente(data_u0, 2, tspan),
        label = "Trabajo"
    )
    plot!(ambientes_plot,  fechas_sol,
        variacion_ambiente(data_u0, 4, tspan),
        label = "Compras"
    )
end

ambientes_plot
