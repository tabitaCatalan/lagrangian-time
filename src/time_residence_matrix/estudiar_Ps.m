% Script para construccion de P con diferentes opciones y visualizacion.

considerar_nvl_socioecono = true;
tipo_nvl_socio = 'ips';
%tipo_nvl_socio = 'promedio';
considerar_no_viajeros = true;
restar_horas_sueno = true;
modo_normalizacion = 0; 

[P, ambientes, nombres_clases, total_por_clase] = procesar_datos_y_obtener_P(...
    considerar_nvl_socioecono, considerar_no_viajeros, restar_horas_sueno, ...
    modo_normalizacion, tipo_nvl_socio);
%%
tomar_log = false;
nclases = length(total_por_clase);
quitar_columnas = 0;

ver_P_v2(P, considerar_nvl_socioecono,...
    considerar_no_viajeros, restar_horas_sueno, modo_normalizacion, ...
    ambientes, nclases, nombres_clases, tomar_log, tipo_nvl_socio, quitar_columnas)
%% Export to .mat
save('Pdata.mat', 'P', 'ambientes', 'nombres_clases', 'total_por_clase')

%%% Separar por temporada



