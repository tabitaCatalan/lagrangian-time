%% Leer base de datos EOD2012, corregir y guardar en una variable de Matlab.
% Autor: Tabita Catalan

%% Requerimientos
% |sqlite3| debe estar en el PATH de Matlab.
% Obtener de <https://www.mathworks.com/matlabcentral/fileexchange/68298-sqlite3>

addpath('C:\Users\Tabita\Documents\MATLAB\sqlite3') % path a sqlite3

%% Leer base de datos
% Se lee la base de datos y e guarda como tabla.
eod_db = '../../data/EOD2012-Santiago.db';
sql_query = fileread('viajes-query.sql');

viajes_data = struct2table(sqlite3(eod_db, sql_query));

%% Correcciones al formato de los datos
% 
% *Cambiar columnas de tipo _cell array_ por array de _doubles_*

% Las celdas vacias se reemplazan por |NaN|
columnas_malas = [4,9,11,12,15,16,18,19,20,21];
for columna = columnas_malas
    viajes_data{cellfun(@isempty,viajes_data{:,columna}), columna} = {nan};
end

%% Se extraen los valores
extract_value = @(x) x(1);
viajes_data.ocupacion = cellfun(extract_value, viajes_data{:,4});
viajes_data.proposito = cellfun(extract_value, viajes_data{:,9});
viajes_data.comuna_origen = cellfun(extract_value, viajes_data{:,15});
viajes_data.comuna_destino = cellfun(extract_value, viajes_data{:,16});
viajes_data.xo = cellfun(extract_value, viajes_data{:,18});
viajes_data.yo = cellfun(extract_value, viajes_data{:,19});
viajes_data.xd = cellfun(extract_value, viajes_data{:,20});
viajes_data.yd = cellfun(extract_value, viajes_data{:,21});

% *Cambiar el formato de las horas*
% El formato original es un string que incluye una fecha (mala). Se
% transforma a una fraccion del dia. 
viajes_data.hora_inicio = cellfun(@extract_frac_hour, viajes_data{:,11});
viajes_data.hora_fin = cellfun(@extract_frac_hour, viajes_data{:,12});


%% Guardar el resultado
% La tabla resultante se guarda en el archivo |viajes.mat|, en la carpeta
% |results|.
viajes_data_filename = '..\..\results\viajes';
viajes_data = viajes_data{:,:};
save(viajes_data_filename, 'viajes_data')