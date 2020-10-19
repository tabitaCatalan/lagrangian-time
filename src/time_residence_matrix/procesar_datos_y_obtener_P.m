function [P, ambientes, nombres_clases, total_por_clase] = procesar_datos_y_obtener_P(...
    considerar_nvl_socioecono, considerar_no_viajeros, restar_horas_sueno, ...
    modo_normalizacion, tpo_nvl_socio)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input:
    % - considerar_nvl_socioecono: boolean
    % - considerar_no_viajeros: boolean
    %   Si verdadero, se agregan los no viajeros
    % - restar_horas_sueno: boolean
    %   Si verdadero, quita 7 horas del tiempo en el hogar
    % - modo_normalizacion: 0,1,2
    %   A priori, la matriz P obtenida no va a sumar 1 por filas.
    %   0: no normalizar
    %   1: se corrige cambiando el ultimo ambiente (otros)
    %   2: se corrige dividiendo por el total por fila
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Output:
    % - P: proporcion de tiempo invertido por cada clase en cada ambiente,
    %   sumar 1 por fila si se normaliza.
    % - ambientes: categorical
    %   nombres de los ambientes usados
    % - nombres_clases: categorical
    %   nombres de las clases usadas
    % - total_por_clase:
    %   cantidad de personas consideradas en cada clase
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % load viajes_data, datos de todos los viajes realizados. Esto carga
    % una estructura.
    viajes_data = load('../../results/viajes.mat','viajes_data');
    % Se extrae la matriz de viajes
    viajes_data = viajes_data.viajes_data;

    ambientes = get_ambientes();

    % Procesar viajeros (personas que hicieron al menos un viaje)
    indices_viajeros = identificar_viajeros();
    [nclases, clase_personas, ~, nombres_clases, ~, ~] = obtener_clases(considerar_nvl_socioecono, tpo_nvl_socio);
    [residencia_por_viaje, bad_index] = procesar_viajes(viajes_data,indices_viajeros);
    [tpo_en_ambiente, viajeros_por_clase] = tiempo_por_clase_vs_ambientes_viajeros(...
        residencia_por_viaje, bad_index, clase_personas, nclases);

    % Procesar no viajeros
    no_viajeros_clase =  no_viajeros_por_clase(clase_personas, indices_viajeros);
    
    % Calcular matriz P.
    [P, total_por_clase] = get_P(tpo_en_ambiente, viajeros_por_clase, ...
        no_viajeros_clase, considerar_no_viajeros, restar_horas_sueno, ...
        modo_normalizacion);
end

