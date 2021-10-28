# Cálculo de la matriz de tiempos de residencia
La base de datos usada es `EOD2012-Santiago.db`, de la carpeta `data`, la cual se trabaja usando [sqlite3](https://www.mathworks.com/matlabcentral/fileexchange/68298-sqlite3).

## Obtener viajes realizados
El script principal es `read_EOD.m`, el cual hace lo siguiente:
1. Lee la base de datos con la consulta de `viajes-query.sql`. 
2. Realiza algunas transformaciones a los datos. En particular, se usa la función `extract_frac_hour.m`. Para más detalles, ver la [documentación](../../doc/read_EOD.html).
3. Guarda un archivo `viajes.mat` en la carpeta `results`. Revisar el [README](../../results/README.md) para más detalles.

## Obtener clases
Se busca separar a la población en base a varios criterios:

### Edad

- Tramo 1: 0-24 años
- Tramo 2: 25-64 años
- Tramo 3: 65 o más años.

### Sexo

- Masculino 
- Femenino

### Nivel Socioeconómico

Hay varias formas de elegirlo. Se plantean las siguientes posibilidades:
- Usar la columna `TramoIngresoFinal` de la tabla `Persona`, que asigna un valor entre 1 y 6 a cada uno de los encuestados en base a su ingreso. Esto NO es un buen indicador, pues una gran proporción de la población queda sin clasificar (tramo 0): quienes no reciben ingresos. Esto incluye a una gran cantidad de estudiantes y amas de casa.
- **Ingreso per cápita:** Se considera el ingreso del hogar (columna `IngresoHogar` de la tabla `Hogar`) dividido por el número de habitantes del hogar (columna `NumPer` de la tabla `Hogar`). Haciendo un ranking de ese ingreso, se separa a la población en 3 tramos:

Tramo | Ingreso mínimo ($) | Ingreso máximo ($)
---|---:|---:
1 | 0       | 76 436
2 | 76 437  | 111 666
3 | 111 667 | 149 999
4 | 150 000 | 199 999
5 | 200 000 | 302 804
6 | 302 805 | ∞

Los ingresos de corte fueron elegidos simplemente para que quedara una cantidad similar de personas en cada grupo.
- **Tramo máximo por hogar:** Se considera el `TramoIngresoFinal` más alto de todas las personas del mismo hogar, y se le asigna a todos los habitantes del hogar.
- **Tasa de pobreza:** Se usa la tasa de pobreza de la comuna a la que pertenece el hogar (ver descripción de los datos para detalles de cómo se obtiene). Se separa a la población en 3 tramos:

Tramo | Tasa mínima | Tasa máxima
--- | ---   |---
1   | 10%   | 100%
2   | 5%    | <10%
3   | 0%    | <5%

- **IPS:** Se usa el índice de prioridad social (ver descripción de los datos para más detalles).
<!-- Se separa a la población en 3 tramos:

Tramo | IPS mínimo | IPS máximo
--- | ---   |---
1   | 72    | ∞
2   | 58    | <72
3   | 0    | <58
-->
Se separa a la población en 5 tramos. Ver Issue #9 :

Tramo | IPS mínimo | IPS máximo
--- | ---    |---
1   | >77.39 | ∞
2   | >71.36 | 77.39
3   | >64.37 | 71.36 
4   | >37.36 | 64.37
4   | >6... | 37.36

Para generar los tramos a los que pertenece cada persona en cada uno de los criterios se usa la consulta `clases-query.sql`.

## Calcular la matriz
Se usa el script `estudiar_Ps.m`. Hay varios parámetros que pueden ser ajustados por el usuario. Ver la documentación para más detalles.
