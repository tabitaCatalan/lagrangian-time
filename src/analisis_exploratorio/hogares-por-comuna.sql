/*
Consulta para conocer las comunas a las que pertenecen los hogares encuestados en la EOD2012
*/
SELECT ComunasSantiago.id_comuna,
Hogar.Comuna, COUNT(Hogar.Hogar)
FROM Hogar
INNER JOIN ComunasSantiago
ON Hogar.Comuna = ComunasSantiago.Comuna
GROUP BY Hogar.Comuna
ORDER BY Hogar.Comuna;