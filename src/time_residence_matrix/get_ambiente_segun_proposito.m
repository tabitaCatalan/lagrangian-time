function destino = get_ambiente_segun_proposito()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Output:
    % - destino: arreglo de largo 14.
    %   destino(i) da el ambiente del modelo asociado al proposito i-esimo.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Se consideran los siguientes propositos
    % 1: Al trabajo, 2: Por trabajo, 3: Al estudio, 4: Por estudio,
    % 5: De salud, 6: Visitar a alguien, 7: Volver a casa,
    % 8: Buscar o dejar a alguien, 9: Comer o tomar algo
    % 10: Buscar o dejar algo, 11: De compras, 12: Tramites, 13: Recreacion
    % 14: Otra actividad
    %
    % Los 13 ambientes del modelo son
    % 1: hogar, 2: trabajo, 3: estudios, 4: compras, 5: visitas, 6: salud
    % 7: tramites, 8: recreo, 9: transporte publico, 10: auto, 11: caminata,
    % 12: bicicleta, 13: otros
    %
    % Propositos incluidos en cada ambiente:
    % 
    % Ambiente                  | Propositos asociados
    % --------------------------|---------------------------------
    % 1: hogar                  | 7
    % 2: trabajo                | 1, 2
    % 3: estudios               | 3, 4
    % 4: compras                | 9, 10, 11
    % 5: visitas                | 6, 8
    % 6: salud                  | 5
    % 7: tramites               | 12
    % 8: recreo                 | 13
    %13: otros                  | 14
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    destino = [2, 2, 3, 3, 6, 5, 1, 5, 4, 4, 4, 7, 8, 13]; 
end