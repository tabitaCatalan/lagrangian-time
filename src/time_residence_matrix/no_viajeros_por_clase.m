function personas_por_clase =  no_viajeros_por_clase(clase_personas, indices_viajeros)
    % 
    % Cuenta la cantidad de personas que no viajan en cada clase
    %
    %%%%%%%%%%%%
    % Input:
    % - clase_personas:
    %   Listado de las clases de todas las personas (contando a viajeros y no viajeros).
    %   Se llamara total_personas al largo de este array.
    % - indices_viajeros:
    %   indices de las personas que hicieron al menos un viaje 
    %   (enumerando a las personas 1..total_personas)
    %%%%%%%%%%%%
    % Output:
    % - personas_por_clase: array de largo 18 (cantidad de clases)
    %   cantidad de personas que no viajan, separados por clases
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    clase_personas(indices_viajeros) = []; % elimino viajeros
    
    %clases = (1:18)';
    G = findgroups(clase_personas); % la clase 1 seran los sin clasificar
    personas_por_clase = splitapply(@numel, clase_personas, G);  % cuento cuantos hay de cada clase
    
    if ~ sum(clase_personas == 0) == 0 % hay gente sin clasificar
        personas_por_clase = personas_por_clase(2:end);
    end
end