# Modificaciones a los datos.

## Datos de Movilidad del ISCI
Se encuentran en el archivo `datos-movilidad-isci.csv`.

Originalmente las variaciones del porcentaje estaban en dos columnas con el sgte formato:
`dif_salida` | `dif_entrada`
--- |---
`"[-40%,-21%,]"` | `"[-100%,-61%]"`

Eso se cambió por cuatro columnas:

`p100_dif_salida_min` | `p100_dif_salida_max` | `p100_dif_entrada_min` | `p100_dif_entrada_max`
--- |--- | --- |---
-40 | -21| -100 |-61



## Encuesta Origen-Destino
Se trabajó con SQLite. El archivo `EOD2012-Santiago.db` fue modificado para agregar más información. Se agregaron las siguientes tablas:
- `ComunasSantiago`: Contiene la información del archivo `ComunasSantiago.csv`. Vincula las comunas de la EOD (que se identifican por nombre) con información externa acerca de las comunas como los índices de pobreza y vulnerabilidad (que se identifican por código único territorial).
- `IPS`: Contienen la información de `IPS2019_por_comuna_RM.csv`. La tabla se creó usando `crear-ips.sql`. 
- `TasaPobreza`: Contiene la información de `TasaPobrezaComunal2013.csv`. La tabla se creó usando `crear-tasa-pobreza.sql`.

## IPS
Los datos se obtuvieron traspasándolos manualmente a partir del pdf fuente.

## Tasa de Pobreza
Originalmente venían en un Excel que contenía bastante más información. Se extrajo solamente la información de la tasa de pobreza comunal, junto al código territorial.

# Comentarios acerca de los datos 
Para simplificar el proceso de creación de tablas en SQLite, los csv están delimitados por `,`. El separador decimal usado es `.`. La tabla se creó primero con el archivo `.sql` respectivo, y luego se rellenó con los datos del archivo `.csv`. Para hacer el `.csv` no debe tener encabezado.

Las tablas se crean de la siguiente forma:
```
sqlite> .mode csv
sqlite> .read data/crear-ips.sql 
sqlite> .import data/IPS2019_por_comuna_RM.csv IPS
```
Para revisar la tabla creada (nos limitamos a las primeras 5 entradas)
```
sqlite> .headers on
sqlite> .mode columns
sqlite> SELECT * FROM IPS LIMIT 5;
id_comuna  ips  
---------  -----
13112      83.03
13116      81.78
13103      81.04
13131      80.28
13603      80.28
```
Para la tabla `TasaPobreza` es análogo.