/*
Crear tabla con las comunas de Santiago, con datos como IPS y tasa de pobreza.
*/
CREATE TABLE IF NOT EXISTS "ComunasSantiago" (
    "id_comuna" INTEGER, 
    "Comuna" TEXT,
    "ips" REAL, 
    "tasa_pobreza" REAL
); 