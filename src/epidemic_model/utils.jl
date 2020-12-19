#=
Funciones útiles que se usan en varios otros archivos
=#


function linear_regression(x,y)
    n = length(x)
    M = reshape([ones(n); x], (n,2))
    v = M\y
    v[2], v[1]
end
