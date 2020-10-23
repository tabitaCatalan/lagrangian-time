#=
Este archivo intenta una nueva versión del modelo usando Callbacks

Callback Library:
https://diffeq.sciml.ai/dev/features/callback_library/#callback_library

Specific Array Types
https://diffeq.sciml.ai/dev/features/diffeq_arrays/#control_problem
=#

using ComponentArrays
using DifferentialEquations
using StaticArrays

# Quiero una función que modifique la matriz P ... dependiendo de....
# Array{3} (Ponderadores de las 3 clases) → ponderacion entre matriz P normal y P cuarentena
"""
    matrix_ponderation!(P, P_normal, P_cuarentena, frac_cuarentena_por_clase)
Recibe la fracción de personas en cuarentena en cada clase social. Devuelve la matriz P 
que es una ponderación de la matriz P en condiciones normales y en cuarentena.
# Argumentos 
- `P`: preallocated matrix 
    Para guardar el resultado
- `P_normal:` matrix de tiempos de residencia normal 
- `P_cuarentena`: matriz de tiempos de residencia en cuarentena total
- `frac_cuarentena_por_clase`: fracción de personas en cuarentena por clase 
    - `frac_cuarentena_por_clase[1]`: clase baja
    - `frac_cuarentena_por_clase[2]`: clase media
    - `frac_cuarentena_por_clase[3]`: clase alta
"""
function matrix_ponderation!(P, P_normal, P_cuarentena, frac_cuarentena_por_clase)
    mapping = @SArray [1,1,2,2,3,3,1,1,2,2,3,3,1,1,2,2,3,3]
    P .= frac_cuarentena_por_clase[mapping]*P_cuarentena + (1-frac_cuarentena_por_clase[mapping])*P_normal
end 

# Necesito algo que dado el tiempo me dé la ponderacion
# Eso va a requerir que lea la base de datos...
# O que tenga un array con eso guardado




mutable struct MyDataArray{T,1} <: DEDataArray{T,1}
    x::ComponentArray{T,1}
    P::Array{T,2}
end
