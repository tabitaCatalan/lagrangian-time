

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





function incidencia_por_clase(sol, index_clase; total_por_clase)
    i = 3*n_clases+1:4*n_clases
    return sum(sol'[:, i[index_clase]], dims = 2)/sum(total_por_clase[index_clase])
end

function total_por_clase(sol, index_clase; estado = 1:18)
    return sum(sol'[:, estado[index_clase]], dims = 2)
end

plot_all_states_and_save(sol3,
    output_folder*"all-states_clase-alta_mov-norm_s0-normal.png";
    indexs = clase_alta
)

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
#ν = nu*ones(n_clases)
#φ = phi
#γ = gi*ones(n_clases)
#γₘ = gm*ones(n_clases)
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
