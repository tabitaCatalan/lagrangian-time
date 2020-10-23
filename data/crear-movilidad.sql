/*
Creado a partir de los datos de movilidad de Google

CREATE TABLE IF NOT EXISTS "Movilidad" (
    date_ms TEXT,
    recr_p100_change_from_base INTEGER,
    groc_p100_change_from_base INTEGER,
    park_p100_change_from_base INTEGER,
    tran_p100_change_from_base INTEGER,
    work_p100_change_from_base INTEGER, 
    home_p100_change_from_base INTEGER
);*/
CREATE TABLE IF NOT EXISTS "MovBaseMarzo" (
    fecha TEXT,
    recr INTEGER,
    compras INTEGER,
    parque INTEGER,
    transporte INTEGER,
    trabajo INTEGER, 
    residencia INTEGER
);

INSERT INTO MovBaseMarzo 
SELECT date_ms,
ROUND((recr_p100_change_from_base - 0.2)/(1+0.2/100)) AS recr,
ROUND((groc_p100_change_from_base - 10.8)/(1+10.8/100)) AS groc,
ROUND((park_p100_change_from_base - 8.8)/(1+8.8/100)) AS park,
ROUND((tran_p100_change_from_base - 9.8)/(1+9.8/100)) AS trans,
ROUND((work_p100_change_from_base - 14.8)/(1+14.8/100)) AS work,
ROUND((home_p100_change_from_base + 0.6)/(1-0.6/100)) AS home
FROM Movilidad;