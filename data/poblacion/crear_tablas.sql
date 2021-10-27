CREATE TABLE IF NOT EXISTS pobla_regiones(
   id_region INT,
   grupo_etario INT,
   hombres INT,
   mujeres INT
);
CREATE TABLE IF NOT EXISTS regiones(
    id_region INT PRIMARY KEY,
    nombre_region TEXT
);
CREATE TABLE IF NOT EXISTS grupos_edades(
    grupo_etario INT PRIMARY KEY,
    edades TEXT
);