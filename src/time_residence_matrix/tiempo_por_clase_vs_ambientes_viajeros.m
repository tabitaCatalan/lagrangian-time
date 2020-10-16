function [tpo_en_ambiente, viajeros_por_clase] =  tiempo_por_clase_vs_ambientes_viajeros(residencia_por_viaje, bad_index, clase_personas, nclases)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input:
    % - residencia_por_viaje:
    %   col 1: persona que hizo el viaje (enumeradas de 1:total_personas,
    %       contando a no viajeron tambien)
    %   col 2: ambiente
    %   col 3: tpo_residencia, 
    %   col 4: ambiente de viaje
    %   col 5: tiempo de viaje
    % - bad_index: 
    %   Los datos de residencia_por_viaje(bad_index,:) no seran considerados
    % - clase_personas:
    %   Listado de las clases de todas las personas(contando a viajeros y
    %   no viajeros)
    % - nclases:
    %   Cantidad de clases usadas
    %%%%%%%%%%%%%%%
    % Output:
    % - tpo_en_ambiente: matrix de nclases x 13 (son 13 ambientes)
    %   cada entrada tiene el total de horas invertidas que gasta la clase
    %   en ese ambiente. Solo considera a los viajeros.
    % - viajeros_por_clase: array de largo nclases.
    %   cuenta el numero de viajeros procesados pertenecientes a cada clase
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    total_viajes = size(residencia_por_viaje,1);

    tpo_en_ambiente = zeros(nclases,13); % clases y 13 ambientes

    viajeros_por_clase = zeros(nclases,1);
    
    destino = get_ambiente_segun_proposito();
    ambientes_viaje = get_ambiente_segun_modo_agregado();
    
    for viaje_k = 1:total_viajes
        if ~bad_index(viaje_k) % indices invalidos no se procesan
            tpo_ambiente = residencia_por_viaje(viaje_k,3);
            tpo_transporte = residencia_por_viaje(viaje_k,5);
            persona = residencia_por_viaje(viaje_k,1); 
            clase = clase_personas(persona);
            if ~isnan(tpo_ambiente) && ~isnan(tpo_transporte) && clase ~= 0
                proposito = residencia_por_viaje(viaje_k,2);

                ambiente = destino(proposito);

                tpo_en_ambiente(clase,ambiente) = tpo_en_ambiente(clase,ambiente) + tpo_ambiente;

                modo = residencia_por_viaje(viaje_k,4); % ARREGLAR ESTO
                ambiente = ambientes_viaje(modo);

                tpo_en_ambiente(clase,ambiente) = tpo_en_ambiente(clase,ambiente) + tpo_transporte;

                viajeros_por_clase(clase) = viajeros_por_clase(clase) + residencia_por_viaje(viaje_k,6); % Esto esta MAL! está contando viajes, no personas.

            end
        end
    end

end