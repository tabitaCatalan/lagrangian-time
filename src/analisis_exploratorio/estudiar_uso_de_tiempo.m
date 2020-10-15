% Script para obtener los datos de uso de tiempo por dia

load('Data.mat', 'Data')
% intervalos en que se discretiza el dia
N = 144; % intervalos de 10 minutos => N = 24*60/10
[actividades, grilla_temporal, bad_index, dia_semana, temporadas] = actividades_durante_dia(Data,N);
%%
[nclases, numeros_clase, tamano_clases, class_names] = obtener_clases(false);
%%
M = zeros(13,N,4);
for temp = 1:2
    for dia = 1:2
        % tipo 1: laboral normal, tipo 2: fin de semana normal,
        % tipo 3: laboral estival, tipo 4: fin de semana estival
        tipo_dia = (temp-1)*2 + dia; 
        for k = 1:N
            vec = accumarray(actividades(~bad_index & temporadas == temp & dia_semana == dia,k),1);
            M(1:length(vec),k,tipo_dia) = vec;
        end
    end
end
%% exportar
ambientes = get_ambientes();
save('actividades.mat', 'actividades', 'grilla_temporal','M', 'ambientes')

%%
save('tipo_dia_viajeros.mat', 'temporadas', 'dia_semana')