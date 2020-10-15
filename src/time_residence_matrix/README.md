# Cálculo de la matriz de tiempos de residencia

## Obtener viajes realizados
La base de datos usada es `EOD2012-Santiago.db`, de la carpeta `data`. El script principal es `read_EOD.m`, el cual hace lo siguiente:
1. Se lee la base de datos usando [sqlite3](https://www.mathworks.com/matlabcentral/fileexchange/68298-sqlite3). La consulta de SQL se encuentra en el archivo `viajes-query.sql`. 
2. Se realizan algunas transformaciones a los datos. En particular, se usa la función `extract_frac_hour.m`. Para más detalles, ver la [documentación](../../doc/read_EOD.html).
3. Se guarda un archivo `viajes.mat` en la carpeta `results`. Revisar el [README](../../results/README.md) para más detalles.

## Calcular la matriz
> :exclamation: 