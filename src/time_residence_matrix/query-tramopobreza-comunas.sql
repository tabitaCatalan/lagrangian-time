/*
Tramo pobreza por comuna
*/
SELECT TasaPobreza.id_comuna, ComunasSantiago.comuna, 
CASE
    WHEN TasaPobreza.p100_pobreza < 5 THEN 3
    WHEN TasaPobreza.p100_pobreza >= 5 AND TasaPobreza.p100_pobreza < 10 THEN 2
    WHEN TasaPobreza.p100_pobreza >= 10 THEN 1
END AS tramo_pobreza
FROM TasaPobreza, ComunasSantiago
WHERE TasaPobreza.id_comuna == ComunasSantiago.id_comuna;