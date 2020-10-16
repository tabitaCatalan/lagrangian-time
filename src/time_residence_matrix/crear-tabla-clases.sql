/* crear tabla de clases. Esta tabla se rellenara despues con los datos
de la consulta clases-query.sql*/
CREATE TABLE IF NOT EXISTS "Clases" (
	"id_persona" INTEGER,
	"id_hogar" INTEGER, 
    "grupo_edad" INTEGER,
    "sexo" INTEGER,
    "ingreso_hogar_promedio" REAL, 
    "tramo_ingreso_promedio" INTEGER,
    "tramo_ingreso_final_por_persona" INTEGER, 
    "temporada" INTEGER,
    "tipo_dia" INTEGER, 
    "tramo_ips" INTEGER,
    "tramo_pobreza" INTEGER
); 