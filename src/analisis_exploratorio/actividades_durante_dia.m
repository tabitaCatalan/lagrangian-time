function [ambiente, horas, bad_indexs, dia_semana, temporadas] = actividades_durante_dia(Data, N)
    % ACTIVIDADES_DURANTE_DIA Calcula una matriz que contiene informacion
	% de la ubicacion de cada uno de los viajeros durante el dia.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Input:
    % - Data: matriz
    %       contiene informacion de todos los viajes realizados. Supone:
	% 		- La columna 6 tiene el tipo de dia: laboral (1) o fin de semana (2).
	% 		- La columna 7 tiene la temporada: normal (1) o estival (2)
	% 		- La columna 9 contiene el proposito del viaje.
	% 		- La columna 10 contiene el modo de viaje (transporte usado)
	% 		- Las columnas 11 y 12 contienen la hora de inicio y fin respect.
	% 		  del viaje (como fraccion del dia)
    % - N: int
    %       cantidad de intervalos en que discretiza el dia
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Output:
    % - M: matriz, cantidad de personas x N
    %   M_{ij} es el ambiente en el que estaba la persona  i a la hora
    %   (j-1)/N (se considera que un dia tiene valor 1).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    horas = linspace(0,1,N+1); % discretizacion de un dia
    horas = horas(1:end-1); % eliminar ultimo

    total_viajes = size(Data,1);

    volver_a_casa = 7;
    hogar = 1;
    desconocido = 13;
    hora_de_corte = 4/24;

    id_viaje = Data(:,1);
    id_persona_repetido = floor(id_viaje/100);
    [~, indices_primer_viaje, ~] = unique(id_persona_repetido);
    
    indices_personas_extra = [indices_primer_viaje; total_viajes + 1];
    viajes = indices_personas_extra(2:end)-indices_personas_extra(1:end-1);


    ambientes_de_transporte = get_ambiente_segun_modo_agregado();
    ambientes_de_residencia = get_ambiente_segun_proposito();

    primer_viaje = 1;
    persona = 1;

    total_personas = length(indices_primer_viaje);
    ambiente = zeros(total_personas,N);

    bad_indexs = zeros(total_personas,1);
    dia_semana = zeros(total_personas,1);
    temporadas = zeros(total_personas,1);

    while primer_viaje <= total_viajes
        viajes_persona = viajes(persona);

        dia_semana(persona) = sum(Data(primer_viaje:primer_viaje + viajes_persona-1, 6))/viajes_persona;
        temporadas(persona) = sum(Data(primer_viaje:primer_viaje + viajes_persona-1, 7))/viajes_persona;

        no_hay_proposito_NaN = ~(sum(isnan(Data(primer_viaje:primer_viaje + viajes_persona-1, 9))) > 0);
        no_hay_horas_NaN = ~(sum(sum(isnan(Data(primer_viaje:primer_viaje + viajes_persona-1, 11:12)))) > 0);

        if no_hay_proposito_NaN && no_hay_horas_NaN
            
            proposito_inicial = Data(primer_viaje,9);
            
            hora_inicio_primer_viaje=Data(primer_viaje,11);
            
            if proposito_inicial == volver_a_casa || isnan(proposito_inicial)
                ambiente(persona, rango_indices(horas, hora_de_corte, hora_inicio_primer_viaje)) = desconocido;
            else
                % supongo que comienzo en hogar
                ambiente(persona, rango_indices(horas, hora_de_corte, hora_inicio_primer_viaje)) = hogar;  
            end

            for viaje = 1:viajes_persona
                proposito_actual = Data(primer_viaje + viaje - 1,9);
                if isnan(proposito_actual)
                    proposito_actual = desconocido;
                end
                ambiente_objetivo = ambientes_de_residencia(proposito_actual);

                modo_actual = Data(primer_viaje + viaje - 1,10);
                ambiente_viaje = ambientes_de_transporte(modo_actual);

                hora_inicio_actual = Data(primer_viaje + viaje - 1,11);
                hora_fin_actual = Data(primer_viaje + viaje - 1,12);

                ambiente(persona, rango_indices(horas, hora_inicio_actual, hora_fin_actual)) = ambiente_viaje;

                if viaje < viajes_persona % no es el ultimo 
                    hora_inicio_sgte = Data(primer_viaje + viaje, 11);
                else % ultimo viaje
                    hora_inicio_sgte = hora_de_corte;
                end
                ambiente(persona, rango_indices(horas, hora_fin_actual, hora_inicio_sgte)) = ambiente_objetivo;
            end
            if sum(ambiente(persona,:)==0)>0
                bad_indexs(persona) = 1;
            end
        else % hay datos faltantes
            bad_indexs(persona) = 1;
        end
        primer_viaje = primer_viaje + viajes_persona;
        persona = persona + 1;
    end
    bad_indexs = logical(bad_indexs);
end
