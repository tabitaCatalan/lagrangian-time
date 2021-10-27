-- Consulta: 
-- Obtener poblacion de distintos grupos de edad y genero a nivel nacional 
SELECT
    CASE 
        WHEN GE.grupo_etario <= 5 THEN "joven"
        WHEN GE.grupo_etario > 5 and GE.grupo_etario <= 13 THEN "adulto"
        WHEN GE.grupo_etario > 13 THEN "mayor"
    END AS grupo_etario_agrupado,
    --count(GE.edades) AS cuantos_grupos,
    sum(PR.hombres) as total_hombres,
    sum(PR.mujeres) as total_mujeres
FROM grupos_edades AS GE INNER JOIN pobla_regiones AS PR ON GE.grupo_etario = PR.grupo_etario
GROUP BY grupo_etario_agrupado;