function indices_viajeros = identificar_viajeros()
    % Importar tabla con cantidad de viajes por persona
    % para obtener indices de las personas que viajan
    
    eod_db = '../../data/EOD2012-Santiago.db';
    sql_query = fileread('numero-viajes-ppersona.sql');

    viajes_por_persona = struct2table(sqlite3(eod_db, sql_query));

	% tal vez no necesito el find...
    indices_viajeros = find(viajes_por_persona{:,2} > 0); % indices de quienes hacen al menos un viaje
end