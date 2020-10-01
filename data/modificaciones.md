# Modificaciones a los datos.

## `datos-movilidad-isci.csv`

Originalmente las variaciones del porcentaje estaban en dos columnas con el sgte formato:
`dif_salida` | `dif_entrada`
--- |---
`"[-40%,-21%,]"` | `"[-100%,-61%]"`

Eso se cambió por cuatro columnas:

`p100_dif_salida_min` | `p100_dif_salida_max` | `p100_dif_entrada_min` | `p100_dif_entrada_max`
--- |--- | --- |---
-40 | -21| -100 |-61

