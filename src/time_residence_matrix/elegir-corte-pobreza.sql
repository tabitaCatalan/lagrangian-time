/*
Elegir valores de corte para la tasa de pobreza,
de tal forma de dejar aproximadamente la misma cantidad 
de personas en cada grupo.
Para 
- Tramo 1: 10 <= p100_pobreza 
- Tramo 2: 5 <= p100_pobreza < 10
- Tramo 3: p100_pobreza < 5
Se obtiene:
TramoPobreza  TotalPersonas
------------  -------------
1             21766
2             24099        
3             14189
*/
SELECT T.tramo AS TramoPobreza, COUNT(Persona.Persona) AS TotalPersonas
FROM Persona, Hogar, ComunasSantiago, (
    SELECT id_comuna,
    CASE
        WHEN TasaPobreza.p100_pobreza < 5 THEN 3
        WHEN TasaPobreza.p100_pobreza >= 5 AND TasaPobreza.p100_pobreza < 10 THEN 2
        WHEN TasaPobreza.p100_pobreza >= 10 THEN 1
    END AS tramo
    FROM TasaPobreza
) AS T
WHERE Persona.Hogar = Hogar.Hogar 
AND Hogar.Comuna = ComunasSantiago.Comuna
AND ComunasSantiago.id_comuna = T.id_comuna
GROUP BY T.tramo 