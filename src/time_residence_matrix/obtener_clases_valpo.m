function [nclases, numeros_clase, tamano_clases, class_names, ...
    temporada, tipo_dia] = obtener_clases(considerar_nvl_econo)
    % OBTENER_CLASES 
    % Input:
    % - considerar_nvl_econo: boolean
    %   si es verdadero, entonces la clasificacion considera el nivel
    %   socioeconomico.
    % - tipo_nvl: str
    %   Tipo de nvl socioeconomico usado. Las opciones son:
    %   - 'maximo': considera el maximo tramo final de todos los miembros 
    %      del hogar.
    %
    % Output:
    % - nclases:
    %   cantidad de clases usadas
    % - numeros_clase:
    %   array donde la posicion i-esima indica la clase (de 1 a nclases) de
    %   la persona i-esima, considerando a todas las personas del excel
    %   Clases.xlsx
    % - class_names:
    %   array categorico, de largo nclases, con los nombres de las clases.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Se lee la base de datos usando una consulta sql, que devuelve una
    % tabla con los siguientes atributos:
    % 1: id_persona
    % 2: id_hogar
    % 5: grupo_edad
    % 6: sexo 
    % 7: ingreso_hogar_promedio
    % 8: tramo_ingreso_promedio
    % 9: tramo_ingreso_final_ppersona
    % 10: tramo_max  
    % 11: ips
    % 12: tramo_ips
    % 13: tasa_pobreza
    % 14: tramo_pobreza
    %
    % Si considerar_nvl_econo = true, entonces para los tipos 'maximo' y 'promedio'
    % se consideran niveles socioeconomicos agrupando tramos como sigue:
    % Nivel | Tramos
    % 1     | 1:6
    % 2     | 7,8
    % 3     | 9:13
    % tramo_max  num_per
    % ---------  -------
    % 2          82
    % 3          585
    % 4          1619
    % 5          2393   
    % 6          3846
    % 7          5575
    % 8          5211
    % 9          3682
    % 10         1509
    % 11         1002
    % 12         914
    % 13         1086
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Leer base de datos
    % Se lee la base de datos y se guarda como tabla.
    eod_db = '../../data/valparaiso/EOD2014-Valparaiso.db';
    sql_query = fileread('clases-valpo-query.sql');

    Clases = struct2table(sqlite3(eod_db, sql_query));
    Clases = Clases{:,:}; % pasar a matriz
    
    %% Indices de las columnas
    col_edad  = 3;
    col_sexo  = 4;
    tipo_nvl = 'maximo';

    %% Obtener indices de cada clasificacion
    % Sexo
    hombre = (Clases(:,col_sexo)==1);
    mujer = (Clases(:,col_sexo)==2);

    % Edad
    joven = (Clases(:,col_edad)==1);
    adulto = (Clases(:,col_edad)==2);
    mayor = (Clases(:,col_edad)==3);

    npersonas = size(Clases,1);
    numeros_clase = zeros(npersonas,1);
    
    if considerar_nvl_econo

        if strcmp(tipo_nvl, 'promedio') || strcmp(tipo_nvl, 'maximo')
            if strcmp(tipo_nvl, 'promedio')
                %col_tramo = 8;
            elseif strcmp(tipo_nvl, 'maximo')
                col_tramo = 6;
            end
            % Nivel Socioeconomico 1...6, (1 es el menor nivel socioeconomico)
            tramo1 = ismember(Clases(:,col_tramo), 1:6);
            tramo2 = ismember(Clases(:,col_tramo), 7:8);
            tramo3 = ismember(Clases(:,col_tramo),9:13);
        else 
            disp("Por favor ingrese un tipo de nivel socioeconomico valido. Las opciones son 'maximo', 'promedio', 'ips', 'pobreza'.")
        end

        %% Definir clases
        numeros_clase(joven & tramo1 & hombre) = 1;
        numeros_clase(joven & tramo1 & mujer) = 2;
        numeros_clase(joven & tramo2 & hombre) = 3;
        numeros_clase(joven & tramo2 & mujer) = 4;
        numeros_clase(joven & tramo3 & hombre) = 5;
        numeros_clase(joven & tramo3 & mujer) = 6;
        numeros_clase(adulto & tramo1 & hombre) = 7;
        numeros_clase(adulto & tramo1 & mujer) = 8;
        numeros_clase(adulto & tramo2 & hombre) = 9;
        numeros_clase(adulto & tramo2 & mujer) = 10;
        numeros_clase(adulto & tramo3 & hombre) = 11;
        numeros_clase(adulto & tramo3 & mujer) = 12;
        numeros_clase(mayor & tramo1 & hombre) = 13;
        numeros_clase(mayor & tramo1 & mujer) = 14;
        numeros_clase(mayor & tramo2 & hombre) = 15;
        numeros_clase(mayor & tramo2 & mujer) = 16;
        numeros_clase(mayor & tramo3 & hombre) = 17;
        numeros_clase(mayor & tramo3 & mujer) = 18;
        class_names = {...
            'MJovenT1', 'FJovenT1',...
            'MJovenT2', 'FJovenT2',...
            'MJovenT3', 'FJovenT3',...
            'MAdultoT1', 'FAdultaT1',...
            'MAdultoT2', 'FAdultaT2',...
            'MAdultoT3', 'FAdultaT3',...
            'MMayorT1', 'FMayorT1',...
            'MMayorT2', 'FMayorT2',...
            'MMayorT3', 'FMayorT3',...
            };
        %%
        nclases = 18;
    else 
        numeros_clase(joven & hombre) = 1;
        numeros_clase(joven & mujer) = 2;
        numeros_clase(adulto & hombre) = 3;
        numeros_clase(adulto & mujer) = 4;
        numeros_clase(mayor & hombre) = 5;
        numeros_clase(mayor & mujer) = 6;
        nclases = 6;
        class_names ={...
            'MJoven', 'FJoven',...
            'MAdulto', 'FAdulta',...
            'MMayor', 'FMayor',...
            };
    end
    %% Tamanos clases

    tamano_clases = zeros(nclases,1);
    for k = 1:nclases
        tamano_clases(k) = sum(numeros_clase==k);
    end


    %% Hay gente sin clasificar?

    sin_clasificar = sum(numeros_clase == 0);
    disp(sin_clasificar)
    %% guarda id_persona y su clase
    % clase_personas = [Clases(:,1),numeros_clase];
    
    % Temporada y dia
    temporada = Clases(:,col_temp);
    tipo_dia = Clases(:, col_dia);
end







