# Modelo

## Cuarentenas:
Se cuenta con un archivo con las cuarentenas dinámicas, de la forma

comuna | dia_1 | dia_2 |...|dia_n
---|---|---|---|---|
c1 | 0 | 1 | ...|0
c2 | 1 | 1 | ...|1

etc.
Cada comuna pertenece a un tramo (ver tramo pobreza). Esto se puede ver con la consulta `query-poblacion-clase.sql`.

Cada comuna además tiene una población, lo que le da una fracción de la población total.

Necesito que cuando hay cuarentena total.... entonces la matriz que yo tenga sea exactamente la matriz $P_c$ (versión cuarentena). Si no hay nadie en cuarentena, entonces se buscaría $P_n$ (versión normal).

Lo interesante es que cada tramo tiene un descenso asociado... Necesito la fracción de personas de cierta clase...para que tenga sentido cuánto pondero más una que la otra.

Si todas las personas de $T_1$ están en cuarentena (todas las comunas pobres)... entonces mi matriz P debería estar disminuida en un 20% en la zona pobre... y  eso  nomás. 

Estoy pensando que no sé qué tan útil es la fracción de la población con respecto al total. Parece ser que solo necesito la fracción c/r a la cantidad de personas en---
Necesito: total de personas por sector.
Ponderación de personas efectivamente en cuarentena
Y dividir para tener la fracción por sector.