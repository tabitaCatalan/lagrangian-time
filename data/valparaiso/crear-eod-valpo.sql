CREATE TABLE IF NOT EXISTS "Persona" (
    "Hogar" INTEGER,
    "Persona" INTEGER,
    "AnoNac" INTEGER,
    "Sexo" INTEGER,
    "Relacion" INTEGER,
    "Viajes" INTEGER,
    "Estudios" INTEGER,
    "Actividad" INTEGER,
    "AdemasEstudia" INTEGER,
    "AdemasTrabaja" INTEGER,
    "LicenciaConducir" INTEGER,
    "TipoLicencia" INTEGER,
    "TarjetaMerval" INTEGER,
    "PaseEscolar" INTEGER,
    "DondeEstudia" INTEGER,
    "Ocupacion" INTEGER,
    "JornadaTrabajo" INTEGER,
    "NoViaja" INTEGER,
    "TieneIngresos" INTEGER,
    "TramoIngresoDeclarado" INTEGER,
    "ImputaTramo" INTEGER,
    "TramoIngresoFinal" INTEGER,
    "IngresoFinal" INTEGER,
    "Factor_Laboral" REAL,
    "Factor_Sabado" REAL,
    "Factor_Domingo" REAL,
    "Factor" REAL
);

CREATE TABLE IF NOT EXISTS "Viaje"(
    "Hogar" INTEGER,
    "Persona" INTEGER,
    "Viaje" INTEGER,
    "Etapas" INTEGER,
    "ComunaOrigen" INTEGER,
    "ComunaDestino" INTEGER,
    "MacrozonaOrigen" INTEGER,
    "MacrozonaDestino" INTEGER,
    "ZonaOrigen" INTEGER,
    "ZonaDestino" INTEGER,
    "ManzanaOrigen" INTEGER,
    "ManzanaDestino" INTEGER,
    "OrigenCoordX" REAL,
    "OrigenCoordY" REAL,
    "DestinoCoordX" REAL,
    "DestinoCoordY" REAL,
    "Proposito" INTEGER,
    "PropositoEstraus" INTEGER,
    "ModosUsados" INTEGER,
    "ModoViaje" INTEGER,
    "ModoPriPub" INTEGER,
    "HoraIni" TEXT,
    "Horafin" TEXT,
    "HoraMedia" TEXT,
    "TiempoViaje" TEXT,
    "Periodo" INTEGER,
    "CuadrasCaminadas" INTEGER,
    "MinutosCaminados" INTEGER,
    "FactorLaboral" REAL,
    "FactorSabado" REAL,
    "FactorDomingo" REAL,
    "SinInfoOD" INTEGER,
    "TipoViaje" INTEGER
);

CREATE TABLE IF NOT EXISTS "Hogar"(
    "Hogar" INTEGER,
    "Macrozona" INTEGER,
    "Zona" INTEGER,
    "Comuna" INTEGER,
    "Manzana" INTEGER,
    "DirCoordX" REAL,
    "DirCoordY" REAL,
    "Fecha" TEXT,
    "DiaAsig" INTEGER,
    "TipoDia" INTEGER,
    "NumPer" INTEGER,
    "NumVeh" INTEGER,
    "Propiedad" INTEGER,
    "NoSabeNoResponde" INTEGER,
    "MontoDiv" INTEGER,
    "MontoArrEstima" INTEGER,
    "MontoArrPaga" INTEGER,
    "IngresoHogar" INTEGER,
    "Factor_Laboral" REAL,
    "Factor_Sabado" REAL,
    "Factor_Domingo" REAL,
    "Factor" REAL
);