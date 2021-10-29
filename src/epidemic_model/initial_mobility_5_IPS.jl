# Calculate initial mobility from Pdata-5-IPS.mat 
# esta matriz tiene descontadas 7/24 del tiempo en el hogar (7 horas de sueño)
P, total_por_clase, nombre_ambientes, nombre_clases = read_matlab_data("..\\..\\results\\Pdata-5-IPS.mat")
initial_res_time_matrix = [P[:,1] sum(P[:,2:end], dims = 2)]
suma_uno_por_fila!(initial_res_time_matrix)


initial_res_time_matrix_with_sleep = [(P[:,1] .+ 7/24) sum(P[:,2:end], dims = 2)]
suma_uno_por_fila!(initial_res_time_matrix_with_sleep)
#= Sería bueno revisar los totales por clase, para ver si son consistentes. 
Recordar que están ordenados de Bajo a ALto 
total_por_clase 
5365.0
10517.0
11007.0
25518.0
7372.0
=# 