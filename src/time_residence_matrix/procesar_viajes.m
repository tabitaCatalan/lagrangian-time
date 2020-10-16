function [residencia_por_viaje, bad_index] = procesar_viajes(Data,indices_viajeros)
    % Data tiene datos de todos los viajes realizados. La info por columnas es la siguiente:
    %1	id_viaje
    %2	edad
    %3	sexo
    %4  ocupacion
    %5	ingreso
    %6	tipo_dia
    %7	temporada
    %8	viajes
    %9	proposito
    %10	modo
    %11	hora_inicio
    %12	hora_fin
    %13	zona_origen
    %14	zona_destino
    %15	comuna_origen
    %16	comuna_destino
    %17	manhattan
    %18	xo
    %19	yo
    %20	xd
    %21	yd
    
    % Tiempos de residencia (en fraccion del dia)
    ndata=size(Data,1); 
    id_viaje=Data(:,1);
    persona=floor(id_viaje/100);
    [~, indices_personas, ib]=unique(persona);
    %%
    indices_personas_extra=[indices_personas; ndata+1];
    viajes=indices_personas_extra(2:end)-indices_personas_extra(1:end-1);
    %%
    tiempo_residencia=zeros(ndata,4);
    % campo 1: ambiente, campo 2: tpo_residencia, 
    % campo 3: ambiente de viaje, campo 4: tiempo de viaje
    i=1; % contador primer viaje
    k=1; % contador personas
    while i<=ndata
        nviajes=viajes(k); % viajes de la persona k
        proposito_inicial=Data(i,9);
        modo=Data(i,10);
        hora_inicio=Data(i,11);
        hora_fin=Data(i,12);
        if nviajes==1 % la persona hizo un unico viaje
            if proposito_inicial==7 % regreso a casa
                tiempo_residencia(i,1)=7; % hogar
                tiempo_residencia(i,2)=1-hora_fin; % tpo hogar desde la hora de regreso hasta 24:00        
            else
                tiempo_residencia(i,1)=7; % hogar
                tiempo_residencia(i,2)=hora_inicio; % tpo hogar de 0:00 hasta la hora de partida        
            end
            tiempo_residencia(i,3)=modo; % modo de transporte        
            tiempo_residencia(i,4)=hora_fin-hora_inicio; % tpo de viaje        
        else
            hora_fin_ultimo_viaje=Data(i+nviajes-1,12);
            tiempo_residencia(i,1)=7; % se asume viajes parten y llegan al final al hogar
            if hora_fin_ultimo_viaje>4/24
                % tpo hogar antes de partir + tpo hogar del ultimo viaje hasta las 24:00
                tiempo_residencia(i,2)=hora_inicio+1-hora_fin_ultimo_viaje;         
            else
                tiempo_residencia(i,2)=hora_inicio-hora_fin_ultimo_viaje;
            end
            tiempo_residencia(i,3)=modo; % modo de transporte primer viaje        
            if hora_fin>=hora_inicio
                tiempo_residencia(i,4)=hora_fin-hora_inicio; % tpo de primer viaje        
            else
                % hora_fin pas? las 0:00 hrs
                tiempo_residencia(i,4)=hora_fin+1-hora_inicio; % tpo de primer viaje                    
            end
            for j=2:nviajes
                proposito_anterior=Data(i+j-2,9);
                proposito_actual=Data(i+j-1,9);
                modo_actual=Data(i+j-1,10);
                hora_inicio_actual=Data(i+j-1,11);
                hora_fin_actual=Data(i+j-1,12);
                hora_inicio_anterior=Data(i+j-2,11);
                hora_fin_anterior=Data(i+j-2,12);
                switch proposito_anterior
                    case 7
                    tiempo_residencia(i+j-1,1)=7; % hogar
                    if hora_inicio_actual>=hora_fin_anterior
                        tiempo_residencia(i+j-1,2)=hora_inicio_actual-hora_fin_anterior; % tpo en hogar
                    else
                        % el tiempo inicio_actual pas? las 0:00
                        tiempo_residencia(i+j-1,2)=hora_inicio_actual+1-hora_fin_anterior; % tpo en hogar
                    end
                    otherwise
                        tiempo_residencia(i+j-1,1)=proposito_anterior; % proposito
                    if hora_inicio_actual>=hora_fin_anterior
                        tiempo_residencia(i+j-1,2)=hora_inicio_actual-hora_fin_anterior; % tpo proposito anterior         
                    else
                        % el tiempo inicio_actual pas? las 0:00
                        tiempo_residencia(i+j-1,2)=hora_inicio_actual+1-hora_fin_anterior; % tpo proposito anterior                             
                    end
                end
                tiempo_residencia(i+j-1,3)=modo_actual; % modo de transporte
                if hora_fin_actual>=hora_inicio_actual
                    tiempo_residencia(i+j-1,4)=hora_fin_actual-hora_inicio_actual; % tpo de viaje        
                else
                % hora_fin_actual pas? las 0:00 hrs
                tiempo_residencia(i+j-1,4)=hora_fin_actual+1-hora_inicio_actual; % tpo de viaje   
                end
            end
        end
        i=i+nviajes;
        k=k+1;
    end
    % marco el primer viaje de cada persona
    primer_viaje = zeros(ndata,1); 
    primer_viaje(indices_personas) = 1;
    residencia_por_viaje = [indices_viajeros(ib),tiempo_residencia, primer_viaje];
    %% Guardar indices malos

    negative_times=(tiempo_residencia(:,2)<0)|(tiempo_residencia(:,4)<0);
    greater_than_one_times=(tiempo_residencia(:,2)>1)|(tiempo_residencia(:,4)>1);
    nan_index = isnan(tiempo_residencia(:,1))|isnan(tiempo_residencia(:,3));

    bad_index = (negative_times | greater_than_one_times | nan_index); % esto es un o logico

end