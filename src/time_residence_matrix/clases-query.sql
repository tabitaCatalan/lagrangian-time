/*
Query para obtener distintas clasificaciones de las personas en la base de datos. 
Se busca separar por sexo, edad y nivel socioeconomico. Este ultimo puede calcularse
de varias formas.
Autor: Tabita Catalan
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
Persona.TramoIngresoFinal AS tramo_ingreso_final_por_persona,
Hogar.Temporada AS temporada,
Hogar.TipoDia AS tipo_dia
--tramo_ips 
FROM Persona, Hogar, EdadPersonas, 
(
    SELECT Hogar.Hogar AS hogar, Hogar.IngresoHogar/Hogar.NumPer AS ingreso_hogar_promedio
    FROM Hogar 
) AS Promedio
WHERE Persona.Hogar = Hogar.Hogar
AND Persona.Persona = EdadPersonas.Persona
AND Promedio.Hogar = Hogar.Hogar
LIMIT 5
;
