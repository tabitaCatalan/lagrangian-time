function ambientes_viaje = get_ambiente_segun_modo_agregado()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Output:
    % - ambientes_viaje: arreglo de largo 18.
    %   ambientes_viaje(i) da el ambiente del modelo asociado al modo
    %   agregado i-esimo.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Se consideran los siguientes Modos Agregados
    % 1:Auto, 2:Bus TS, 3:Bus no TS, 4:Metro, 5:Taxi Colectivo, 6:Taxi
    % 7:Bus TS - Bus no TS, 8:Auto - Metro, 9:Bus TS - Metro,
    % 10:Bus no TS - Metro, 11:Taxi Colectivo - Metro, 12:Taxi - Metro,
    % 13:Otros - Metro, 14:Otros - Bus TS, 15:Otros - Bus TS - Metro,
    % 16:Otros, 17:Caminata, 18:Bicicleta
    %
    % Los ambientes del modelo son
    % 1: hogar, 2: trabajo, 3: estudios, 4: compras, 5: visitas, 6: salud
    % 7: tramites, 8: recreo, 9: transporte publico, 10: auto, 11: caminata,
    % 12: bicicleta
    %
    % Modos agregados incluidos en cada ambiente:
    % 
    % Ambiente              | Modos agregados asociados
    % ----------------------|---------------------------------
    % 9: transporte publico | 2,3,4,5,7,8,9,10,11,12,13,14,15
    % 10: Auto              | 1
    % 12: Bicicleta         | 18
    % 11: Caminata          | 17
    % 13: Otros             | 6,16
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ambientes_viaje = [10,9,9,9,9,13,9,9,9,9,9,9,9,9,9,13,11,12];
end