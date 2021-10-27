-- Consulta: 
-- Obtener poblacion de distintos grupos de edad y genero a nivel nacional 
SELECT
    GE.edades as edad,
    --count(GE.edades) AS cuantos_grupos,
    sum(PR.hombres) as total_hombres,
    sum(PR.mujeres) as total_mujeres
FROM grupos_edades AS GE INNER JOIN pobla_regiones AS PR ON GE.grupo_etario = PR.grupo_etario
GROUP BY GE.grupo_etario;