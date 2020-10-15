# Cálculo de la matriz de tiempos de residencia

El script principal es `read_EOD.m`. La base de datos usada es `..\..\data\EOD2012-Santiago.db`, la cual se lee usando [sqlite3](https://www.mathworks.com/matlabcentral/fileexchange/68298-sqlite3). La consulta de SQL se encuentra en el archivo `viajes-query.sql`. 

Se realizan algunas transformaciones a los datos. Para más detalles, ver la [documentación](../../doc/time_residence_matrix/read_EOD.html).