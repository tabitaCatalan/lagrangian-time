/*
Crear tabla de poblacion por comuna, separando por edad y sexo.
*/
CREATE TABLE IF NOT EXISTS "PoblacionComunasRM" (
    id_comuna INTEGER,
    rango_edad INTEGER,
    hombres INTEGER,
    mujeres INTEGER
);