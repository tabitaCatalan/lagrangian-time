#=
Interfaz para el optimizador de parametros.

# Funciones disponibles:
`optimize_params`
`minimizer`

# Optimizadores disponibles
`BlackBox`
`Gradiente`
=#
using BlackBoxOptim, Optim

###############
### Wrapper ###
###############

abstract type Optimizer end
optimize_params(::Optimizer) = error("Optimizador no reconocido")
minimizer(::Optimizer) = error("Optimizador no reconocido")

###########################################
### Optimizador usando BlackBoxOptim.jl ###
###########################################

mutable struct  BlackBox <: Optimizer
    _setup
    _results

    function BlackBox(cost_function, lower, upper)
        N = length(lower)
        setup = bbsetup(cost_function, SeachRange = ((lower[i], upper[i]) for i in 1:N), NumDimensions = N)
        res = bboptimize(setup, MaxSteps = 1)
        new(setup, res)
    end
end

function optimize_params(bb::BlackBox; max_steps = 10000)
    bb._results = bboptimize(bb._setup, MaxSteps = max_steps)
end

function minimizer(bb::BlackBox)
    bb._results.archive_output.best_candidate
end

###################################
### Optimizador usando Optim.jl ###
###################################

mutable struct Gradiente <: Optimizer

    _inner_optimizer
    _results

    function Gradiente(cost_function, lower, upper; x0 = (lower + upper)/2, time_limit = 300.)
        inner_optimizer = GradientDescent()
        results = optimize(cost_function, lower, upper, x0,
            Fminbox(inner_optimizer),
            Optim.Options(time_limit = time_limit)
            )
        new(inner_optimizer, results)
    end
end

function optimize_params(gr::Gradiente; max_time = 300)
    gr._results = optimize(cost_function, lower, upper, x0,
        Fminbox(inner_optimizer),
        Optim.Options(time_limit = time_limit)
        )
end

function minimizer(gr::Gradiente) gr._results.minimizer end
