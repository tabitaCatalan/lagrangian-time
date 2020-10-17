/*
Query para obtener distintas clasificaciones de las personas en la base de datos. 
Se busca separar por sexo, edad y nivel socioeconomico. Este ultimo puede calcularse
de varias formas.
*/
SELECT Persona.Persona AS id_persona,
Hogar.Hogar AS id_hogar,
CASE 
    WHEN EdadPersonas.Edad < 25 THEN 1 
    WHEN EdadPersonas.Edad >= 25 AND EdadPersonas.Edad < 65 THEN 2
    WHEN EdadPersonas.Edad >= 65 THEN 3
END AS grupo_edad,
Persona.Sexo AS sexo,
Promedio.ingreso_hogar_promedio AS ingreso_hogar_promedio,
CASE
    WHEN Promedio.ingreso_hogar_promedio > 0 AND Promedio.ingreso_hogar_promedio < 76437 THEN 1
    WHEN Promedio.ingreso_hogar_promedio >= 76437 AND Promedio.ingreso_hogar_promedio < 111667 THEN 2
    WHEN Promedio.ingreso_hogar_promedio >= 111667 AND Promedio.ingreso_hogar_promedio < 150000 THEN 3
    WHEN Promedio.ingreso_hogar_promedio >= 150000 AND Promedio.ingreso_hogar_promedio < 200000 THEN 4
    WHEN Promedio.ingreso_hogar_promedio >= 200000 AND Promedio.ingreso_hogar_promedio < 302805 THEN 5
    WHEN Promedio.ingreso_hogar_promedio >= 302805 THEN 6
    ELSE 0
END AS tramo_ingreso_promedio,
Persona.TramoIngresoFinal AS tramo_ingreso_final_ppersona,
Hogar.Temporada AS temporada,
Hogar.TipoDia AS tipo_dia,
IPS.ips AS ips,
CASE
    WHEN IPS.ips >= 72 THEN 1
    WHEN IPS.ips >= 58 AND IPS.ips < 72 THEN 2
    WHEN IPS.ips < 58 THEN 3
END AS tramo_ips,
TasaPobreza.p100_pobreza as tasa_pobreza, 
CASE
    WHEN TasaPobreza.p100_pobreza < 5 THEN 3
    WHEN TasaPobreza.p100_pobreza >= 5 AND TasaPobreza.p100_pobreza < 10 THEN 2
    WHEN TasaPobreza.p100_pobreza >= 10 THEN 1
END AS tramo_pobreza
FROM Persona, Hogar, EdadPersonas, 
(
    SELECT Hogar.Hogar AS hogar, Hogar.IngresoHogar/Hogar.NumPer AS ingreso_hogar_promedio
    FROM Hogar 
) AS Promedio, 
ComunasSantiago, IPS, TasaPobreza
WHERE Persona.Hogar = Hogar.Hogar
AND Persona.Persona = EdadPersonas.Persona
AND Promedio.Hogar = Hogar.Hogar
AND Hogar.Comuna = ComunasSantiago.Comuna 
AND ComunasSantiago.id_comuna = IPS.id_comuna
AND ComunasSantiago.id_comuna = TasaPobreza.id_comuna
LIMIT 5
;
