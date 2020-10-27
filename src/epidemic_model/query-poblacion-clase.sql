/*
Query población e índice por comunas
*/
SELECT PoblaTotalComuna.id_comuna, 
Tramo.tramo_pobreza AS tramo_pobreza,
(PoblaTotalComuna.poblacion) AS poblacion_total,
((PoblaTotalComuna.poblacion)/Total.total) AS frac_poblacion
FROM 
(
    SELECT id_comuna, (SUM(hombres) + SUM(mujeres)) AS poblacion
    FROM PoblacionComunasRM
    GROUP BY id_comuna
) AS PoblaTotalComuna, 
(SELECT CAST(SUM(hombres) + SUM(mujeres) AS REAL) AS total FROM PoblacionComunasRM) AS Total,
(
    SELECT id_comuna,
    CASE
        WHEN TasaPobreza.p100_pobreza < 5 THEN 3
        WHEN TasaPobreza.p100_pobreza >= 5 AND TasaPobreza.p100_pobreza < 10 THEN 2
        WHEN TasaPobreza.p100_pobreza >= 10 THEN 1
    END AS tramo_pobreza
    FROM TasaPobreza
) AS Tramo
WHERE Tramo.id_comuna = PoblaTotalComuna.id_comuna
--GROUP BY Tramo.tramo_pobreza