function indices_viajeros = identificar_viajeros()
    % Importar tabla con cantidad de viajes por persona
    % para obtener índices de las personas que viajan

    viajes_por_persona =xlsread('./viajes_por_persona.xlsx');

	% tal vez no necesito el find...
    indices_viajeros = find(viajes_por_persona > 0); % indices de quienes hacen al menos un viaje
end