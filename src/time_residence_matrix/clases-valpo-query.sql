/*
Query para obtener distintas clasificaciones de las personas en la base de datos. 
Se busca separar por sexo, edad y nivel socioeconomico. Este ultimo puede calcularse
de varias formas.
*/
SELECT ExtraPersona.id_persona AS id_persona,
Persona.Hogar AS id_hogar,
CASE 
    WHEN ExtraPersona.edad < 25 THEN 1 
    WHEN ExtraPersona.edad >= 25 AND ExtraPersona.edad < 65 THEN 2
    WHEN ExtraPersona.edad >= 65 THEN 3
END AS grupo_edad,
Persona.Sexo AS sexo,
Persona.TramoIngresoFinal AS tramo_ingreso_final_ppersona,
Maximo.maximo AS tramo_max
FROM 
(
    SELECT Persona.Hogar AS hogar, Persona.Persona AS persona,
    (Persona.Hogar*100 + Persona.Persona) AS id_persona,
    (2015 - Persona.AnoNac) AS edad
    FROM Persona
) AS ExtraPersona,
Persona, 
(
    SELECT Persona.Hogar AS hogar, MAX(Persona.TramoIngresoFinal) AS maximo
    FROM Persona
    GROUP BY Persona.Hogar
) AS Maximo
WHERE Maximo.hogar = Persona.hogar
AND ExtraPersona.hogar = Persona.Hogar
AND ExtraPersona.persona = Persona.Persona
ORDER BY ExtraPersona.id_persona
--LIMIT 5
;