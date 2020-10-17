# Datos

Datos usados para los parámetros del modelo. Se trabaja con la Región Metropolitana de Chile. Los datos obtenidos de las fuentes se trabajan antes de poder usarlos. Las modificaciones hechas pueden verse al final, en el Anexo: Modificaciones a los datos.

  
## Comunas de la Región Metropolitana
El archivo `ComunasSantiago.csv` contiene las comunas de la RM y su código único territorial. Los nombres de las comunas coinciden con los usados en la base de datos `EOD2012-Santiago.db`. Esto fue pensado para poder incorporar el código único territorial a esta base de datos, que usaba un código distinto para las comunas, el cual no era ampliamente utilizado, a diferencia del código territorial.
### Descripción
El archivo está delimitado por `;`, en codificación `UTF-8`. Los atributos son: 
- `id_comuna`: código único territorial
- `Comuna`: nombre de la comuna.

## Población de las comunas de la RM, separadas por edad y sexo
La población de cada comuna se obtiene a partir de los datos del CENSO 2017. Los datos fueron agrupados por rangos de edad y por sexo, y se encuentran en el archivo `poblacion_por_comuna_sexo_edad.csv`.
### Descripción
- `id_comuna`: código único territorial de la comuna.
- `rango_edad`:
  - 1: de 0-24 años,
  - 2: de 25-64 años,
  - 3: 65 años o más.
- `hombres`: cantidad de hombres de esa comuna que están en ese rango de edad.
- `mujeres`: cantidad de mujeres de esa comuna que están en ese rango de edad.


## Movilidad en Santiago
Fueron obtenidos del visualizar de movilidad del ISCI. 

## Encuesta Origen-Destino 2012
Base de datos de la encuesta origen destino. Contiene información de viajes e información socioeconómica de los viajeros. El archivo se llama `EOD2012-Santiago.accdb`.

## Índice de Pobreza Comunal
Estimaciones de Tasa de Pobreza por Ingresos por Comunas, según Nueva Metodología de Medición de Pobreza y Aplicación de Metodologías de Estimación para Áreas Pequeñas (SAE) e Imputación de Medias por Conglomerados (IMC), 2013.
### Descripción
- `id_comuna`: código único territorial de la comuna. 
- `p100_pobreza `: porcentaje de la población de la comuna bajo la línea de pobreza.
   


## Clasificación de las comunas de la RM según Índice IPS 
El Índice de Prioridad Social (IPS) permite construir un ranking del nivel socioeconómico de las comunas de la Región Metropolitana de Chile. A mayor IPS, mayor vulnerabilidad. Los datos corresponden a la clasificación del 2019, y se encuentran en el archivo `IPS2019_por_comuna_RM.csv`.
### Descripción
- `id_comuna`: código único territorial de la comuna. 
- `ips ` : índice de prioridad social de la comuna.



# Fuentes

- REGIÓN METROPOLITANA DE SANTIAGO - ÍNDICE DE PRIORIDAD SOCIAL DE COMUNAS 2019. Seremi de Desarrollo Social y Familia Metropolitana.  
Obtenido de [www.desarrollosocialyfamilia.gob.cl](http://www.desarrollosocialyfamilia.gob.cl/storage/docs/INDICE._DE_PRIORIDAD_SOCIAL_2019.pdf) el 24 de septiembre de 2020.
- Códigos Únicos Territoriales. Obtenido de [datosabiertos.ine.cl](https://datosabiertos.ine.cl/dataviews/250601/codigos-unicos-territoriales/) el 24 de septiembre de 2020.
- Datos oficiales Censo 2017. Obtenido de [www.censo2017.cl](http://www.censo2017.cl/descargue-aqui-resultados-de-comunas/) el 24 de septiembre de 2020.
- Variación porcentual de la movilidad en el tiempo en el Gran Santiago, a escala de Zona Censal, y zonas bajo cuarentena. Obtenido de [ISCI Covid Analytics](https://covidanalytics.isci.cl/movilidad/visualizador/) el 24 de septiemnre de 2020.
- Actualización y recolección de información del sistema de transporte urbano, IX Etapa: Encuesta Origen Destino Santiago 2012. Encuesta origen destino de viajes 2012 (Documento Difusión). Obtenido de [SECTRA](http://www.sectra.gob.cl/biblioteca/detalle1.asp?mfn=3253).
- Tasa de pobreza comunal. Obtenido de [Observatorio Social](http://observatorio.ministeriodesarrollosocial.gob.cl/indicadores/datos_pobreza_comunal.php) el 17 de octubre de 2020.

# Anexo: Modificaciones a los datos.

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