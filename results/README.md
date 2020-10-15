# Resultados

En este directorio se encuentran los resultados obtenidos con el código disponible en `src`.

## Viajes 
El archivo `viajes.mat` se obtiene a partir de `../data/EOD2012-Santiago.db`, usando `../src/time_residence_matrix/read_EOD.m`. Cada fila corresponde a un viaje, y cada columna a una variable, que se listan a continuación:

Columna | Nombre | Descripción
--- |---|---
1 | `id_viaje` | Identificador único del viaje.
2 | `edad`| 
3 | `sexo`
4 | `ocupacion`
5 | `ingreso` | Tramo ingreso final
6 | `tipo_dia`
7 | `temporada`
8 | `viajes` | Viajes de la persona creo.
9 | `proposito`
10| `modo`
11| `hora_inicio`
12| `hora_fin`
13| `zona_origen` | Zona censal de origen
14| `zona_destino`
15| `comuna_origen`
16| `comuna_destino`
17| `manhattan` | Distancia entre el punto de origen y destino, en normal Manhattan.
18| `xo` | Coordenada x del origen.
19| `yo` | Coordenada y del origen.
20| `xd` | Coordenada x del destino.
21| `yd` | Coordenada y del destino.

> :blue_book: `id_viaje`
> 
> A partir del identificador de viaje pueden obtenerse la persona que realizó el viaje y el hogar al que pertenece: los primeros 6 dígitos de `id_viaje` es `id_hogar` y los primeros 8 digitos de `id_viaje` es `id_persona`