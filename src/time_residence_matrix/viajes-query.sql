-- Autor: Axel Osses
-- Modificado por: Tabita Catalan
SELECT
Viaje.Viaje as id_viaje, Edad as edad, Sexo as sexo, Persona.Ocupacion as ocupacion,
Persona.TramoIngresoFinal as ingreso, Hogar.TipoDia as tipo_dia,
Hogar.Temporada as temporada, Persona.Viajes as viajes,
Viaje.Proposito as proposito, Viaje.ModoAgregado as modo,
Viaje.HoraIni as hora_inicio, Viaje.HoraFin as hora_fin,
Viaje.ZonaOrigen as zona_origen, Viaje.ZonaDestino as zona_destino, 
Viaje.ComunaOrigen as comuna_origen, Viaje.ComunaDestino as comuna_destino,
DistanciaViaje.DistManhattan as manhattan,
Viaje.OrigenCoordX as xo, Viaje.OrigenCoordY as yo,
Viaje.DestinoCoordX as xd, Viaje.DestinoCoordY as yd
FROM
Persona, Viaje, EdadPersonas, Hogar, DistanciaViaje
WHERE
Viaje.Persona=Persona.Persona and Viaje.Persona=EdadPersonas.Persona
and Viaje.Hogar=Hogar.Hogar and Viaje.Viaje=DistanciaViaje.Viaje;
