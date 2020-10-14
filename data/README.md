# Datos

Datos usados para los parámetros del modelo. Se trabaja con la Región Metropolitana de Chile.

## Clasificación de las comunas de la RM según Índice IPS 
El Índice de Prioridad Social (IPS) permite construir un ranking del nivel socioeconómico de las comunas de la Región Metropolitana de Chile. A mayor IPS, mayor vulnerabilidad. Los datos corresponden a la clasificación del 2019, y se encuentran en el archivo `IPS2019_por_comuna_RM.csv`.
### Descripción
- `id_comuna`: código único territorial de la comuna. 
- `nombre_comuna`: nombre de la comuna.
- `ips ` : índice de prioridad social de la comuna.


  
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

# Fuentes

- REGIÓN METROPOLITANA DE SANTIAGO - ÍNDICE DE PRIORIDAD SOCIAL DE COMUNAS 2019. Seremi de Desarrollo Social y Familia Metropolitana.  
Obtenido de [www.desarrollosocialyfamilia.gob.cl](http://www.desarrollosocialyfamilia.gob.cl/storage/docs/INDICE._DE_PRIORIDAD_SOCIAL_2019.pdf) el 24 de septiembre de 2020.
- Códigos Únicos Territoriales. Obtenido de [datosabiertos.ine.cl](https://datosabiertos.ine.cl/dataviews/250601/codigos-unicos-territoriales/) el 24 de septiembre de 2020.
- Datos oficiales Censo 2017. Obtenido de [www.censo2017.cl](http://www.censo2017.cl/descargue-aqui-resultados-de-comunas/) el 24 de septiembre de 2020.
- Variación porcentual de la movilidad en el tiempo en el Gran Santiago, a escala de Zona Censal, y zonas bajo cuarentena. Obtenido de [ISCI Covid Analytics](https://covidanalytics.isci.cl/movilidad/visualizador/) el 24 de septiemnre de 2020.
