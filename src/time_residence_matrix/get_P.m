function [P, total_por_clase] = get_P(tpo_en_ambiente, viajeros_por_clase, ...
    no_viajeros_clase, considerar_no_viajeros, restar_horas_sueno, ...
    modo_normalizacion)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calcula P a partir de una matriz del tiempo invertido en cada ambiente 
    % por cada clase.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input:
    % - tpo_en_ambientes: matriz de la forma (a_{ij})_{ij}
    %   donde a_{ij} = tiempo total gastado por los viajeros de las clase i en el ambiente j
    % - viajeros_por_clase: array 
    %   cantidad de viajeros procesados en cada clase
    % - no_viajeros_clase: array 
    %   cantidad de no viajeros en cada clase
    % - considerar_no_viajeros: boolean
    %   Si verdadero, se agregan los no viajeros
    % - restar_horas_sueno: boolean
    %   Si verdadero, quita 7 horas del tiempo en el hogar
    % - modo_normalizacion: 0, 1, 2
    %   A priori, la matriz P obtenida no va a sumar 1 por filas.
    %   0: no normalizar
    %   1: se corrige cambiando el ultimo ambiente (otros)
    %   2: se corrige dividiendo por el total por fila
    %
    %%%%%%%%%%%
    % Output:
    % - P: matriz 
    %   proporcion de tiempo invertido por cada clase en cada ambiente,
    %   suma 1 por fila
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    total_por_clase = viajeros_por_clase;
    if considerar_no_viajeros 
        total_por_clase = total_por_clase + no_viajeros_clase;
        
        % cada persona no viajera gasta tiempo 1 (todo el dia) en hogar
        tpo_en_ambiente(:,1) = tpo_en_ambiente(:,1) + no_viajeros_clase;
    end
    
    % descontar 7 horas de sue?o en el hogar
    % tpo_en_ambiente(:,1) = tpo_en_ambiente - 7/24*total_por_clase;
    size(tpo_en_ambiente)
    size(total_por_clase)
    P_ = diag(1./total_por_clase)*tpo_en_ambiente;
    if restar_horas_sueno
        P_(:,1) = P_(:,1) - 7/24;
    end
    % Normalizacion
    switch modo_normalizacion
        case 0
            P = P_;
        case 1
            P = P_;
            P(:,13) = 1 - sum(P(:,1:end-1),2);
        case 2
            P = P_./sum(P_,2);
    end
end

