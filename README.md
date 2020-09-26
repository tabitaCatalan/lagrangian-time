# Modelo Lagrangiano con tiempos de residencia

Repositorio de mi trabajo de tesis: un modelo lagrangiano con tiempos de residencia.


# lagrangian-time
Repositorio de mi trabajo de tesis: un modelo lagrangiano con tiempos de residencia.

## Modelo
En el contexto de modelar la epidema por coronavirus y enfrentar 
Una dificultad a la hora de modelar la epidemia por COVID-19 es la falta de datos de calidad. Debido a la imposibilidad de realizar test a toda la población, el número de individuos contagiados es mayor al real, especialmente en los pacientes asíntomáticos. Liu, Magal, Seydi y Webb plantean [^1] un modelo <img src="/tex/d343a5beaabde2410ecf9f826344ed83.svg?invert_in_darkmode&sanitize=true" align=middle width=21.00464354999999pt height=24.65753399999998pt/> que permite separar a los casos no reportados de los reportados. Mientras que estos últimos entran en cuarentena, los primeros tienen un rol mucho más dinámico.

<p align="center"><img src="/tex/0fd4c19502f4d3c905d2b962e6ff318c.svg?invert_in_darkmode&sanitize=true" align=middle width=341.30036985pt height=78.90491235pt/></p>

Este modelo ha sido estudiado teóricamente y aplicado al caso de Chile[^2]. Nos interesa utilizarlo con un enfoque lagrangiano, considerando el tiempo invertido por diferentes grupos sociales (separados por edad, sexo, etc) en varios ambientes (escuela, hogar, trabajo, etc), como plantea [^3].

Más específicamente, separamos a la población en <img src="/tex/55a049b8f161ae7cfeb0197d75aff967.svg?invert_in_darkmode&sanitize=true" align=middle width=9.86687624999999pt height=14.15524440000002pt/> clases, las cuales interactúan en <img src="/tex/0e51a2dede42189d77627c4d742822c3.svg?invert_in_darkmode&sanitize=true" align=middle width=14.433101099999991pt height=14.15524440000002pt/> ambientes (o áreas de riesgo). Denotamos por <img src="/tex/cdc878864e0b0fcf15dd642c84e40cdd.svg?invert_in_darkmode&sanitize=true" align=middle width=126.90433634999998pt height=24.65753399999998pt/> a la cantidad de individuos de la clase <img src="/tex/77a3b857d53fb44e33b53e4c8b68351a.svg?invert_in_darkmode&sanitize=true" align=middle width=5.663225699999989pt height=21.68300969999999pt/>. Suponemos que la población de la clase <img src="/tex/77a3b857d53fb44e33b53e4c8b68351a.svg?invert_in_darkmode&sanitize=true" align=middle width=5.663225699999989pt height=21.68300969999999pt/> pasa una proporción <img src="/tex/d1a4cab8c6ab93b4374d13c6b30d2178.svg?invert_in_darkmode&sanitize=true" align=middle width=72.81573749999998pt height=24.65753399999998pt/> de su tiempo en el ambiente <img src="/tex/36b5afebdba34564d884d347484ac0c7.svg?invert_in_darkmode&sanitize=true" align=middle width=7.710416999999989pt height=21.68300969999999pt/>, con <img src="/tex/fde52e4e1008d66d7b898ab021f44fcd.svg?invert_in_darkmode&sanitize=true" align=middle width=93.64631429999999pt height=26.438629799999987pt/> para cada <img src="/tex/77a3b857d53fb44e33b53e4c8b68351a.svg?invert_in_darkmode&sanitize=true" align=middle width=5.663225699999989pt height=21.68300969999999pt/>. Para casos extremos, por ejemplo, podría darse que <img src="/tex/1cc1cc670eba94b4fc1a09bb2382b529.svg?invert_in_darkmode&sanitize=true" align=middle width=49.98468914999999pt height=21.18721440000001pt/>, es decir, la clase <img src="/tex/77a3b857d53fb44e33b53e4c8b68351a.svg?invert_in_darkmode&sanitize=true" align=middle width=5.663225699999989pt height=21.68300969999999pt/> no gasta nada de su tiempo en el ambiente <img src="/tex/36b5afebdba34564d884d347484ac0c7.svg?invert_in_darkmode&sanitize=true" align=middle width=7.710416999999989pt height=21.68300969999999pt/>, mientras que <img src="/tex/76c4f9f2477029a8ff0befddd4dedc3c.svg?invert_in_darkmode&sanitize=true" align=middle width=49.98468914999999pt height=21.18721440000001pt/> significa que la clase <img src="/tex/77a3b857d53fb44e33b53e4c8b68351a.svg?invert_in_darkmode&sanitize=true" align=middle width=5.663225699999989pt height=21.68300969999999pt/> pasa todo su tiempo en el ambiente <img src="/tex/36b5afebdba34564d884d347484ac0c7.svg?invert_in_darkmode&sanitize=true" align=middle width=7.710416999999989pt height=21.68300969999999pt/>. Esto nos permite plantear el siguiente modelo:

<p align="center"><img src="/tex/d687d83680e3c898b27ab9e8a2aaf118.svg?invert_in_darkmode&sanitize=true" align=middle width=285.32224379999997pt height=95.5409466pt/></p>
donde la tasa de contagio <img src="/tex/10b25a8965607b9859b33bd6a26ec73b.svg?invert_in_darkmode&sanitize=true" align=middle width=14.239981799999988pt height=22.831056599999986pt/> se define como sigue.
<p align="center"><img src="/tex/e897fe62f30003995e3a8e7fb6520bd7.svg?invert_in_darkmode&sanitize=true" align=middle width=503.869773pt height=50.399845649999996pt/></p>
## Tasa de contagio
En el Reporte 5 [^4] usan matrices de contacto en lugar de tiempos de residencia, pero la idea es interesante. Consideran una matriz de contacto a la que contribuyen varios factores (<img src="/tex/da9bb9c651a1d855dcad50a2221042c6.svg?invert_in_darkmode&sanitize=true" align=middle width=12.10048124999999pt height=14.15524440000002pt/> corresponde a trabajo (*work*), <img src="/tex/8af75b010816e07c6e7ea0b36c897828.svg?invert_in_darkmode&sanitize=true" align=middle width=6.48403469999999pt height=14.15524440000002pt/> es escuela (*school*), <img src="/tex/1664b3ae6b4f970ad6d1357f584e7a59.svg?invert_in_darkmode&sanitize=true" align=middle width=9.132448049999992pt height=22.831056599999986pt/> es hogar (*home*) y <img src="/tex/239d0f44a5e47b075f5f00761873fae1.svg?invert_in_darkmode&sanitize=true" align=middle width=8.219209349999991pt height=14.15524440000002pt/> es otros (*other*)).
<p align="center"><img src="/tex/1d2654565d79bf4c12b852ff3492670d.svg?invert_in_darkmode&sanitize=true" align=middle width=172.98124635pt height=13.698590399999999pt/></p>
Para que esta matriz sea dependiente del tiempo, agregan ponderadores dependientes del tiempo, de tal forma que 
<p align="center"><img src="/tex/ccd8634d58b3a83cedba2a63fbaa987b.svg?invert_in_darkmode&sanitize=true" align=middle width=453.76026959999996pt height=16.438356pt/></p>

En mi caso, no tengo una matriz por ambiente. Más bien, cada una de las columnas de mi matriz corresponde a un ambiente. Así que podría hacer una versión de eso usando el mismo ponderador para cada columna.




## Estimación de parámetros
- Tasas <img src="/tex/4539afac2a2efd311245e55815a656e9.svg?invert_in_darkmode&sanitize=true" align=middle width=29.395131149999987pt height=22.831056599999986pt/>, <img src="/tex/22ec9d72ac74e23d7fa56c01ec091d4d.svg?invert_in_darkmode&sanitize=true" align=middle width=29.04123749999999pt height=22.831056599999986pt/> and <img src="/tex/dc05b60876ba1f740adc640196e4e4d5.svg?invert_in_darkmode&sanitize=true" align=middle width=35.23991294999999pt height=22.831056599999986pt/> y fracción de infectados asintomáticos <img src="/tex/4bf3b705f961202cf70684e2a5e2c9d4.svg?invert_in_darkmode&sanitize=true" align=middle width=23.379115649999992pt height=22.831056599999986pt/> por edad [16]:
- [https://www.medrxiv.org/content/10.1101/2020.03.04.20031104v1.full.pdf](https://www.medrxiv.org/content/10.1101/2020.03.04.20031104v1.full.pdf)
- Inverso de los tiempos de duración de cada etapa <img src="/tex/1c88d08da6ddfb872d36f2a8e21a9cb8.svg?invert_in_darkmode&sanitize=true" align=middle width=50.40039014999999pt height=14.15524440000002pt/> y fracción de infectados que se recupera <img src="/tex/98827dedb6d4aaa76915fc369c890c24.svg?invert_in_darkmode&sanitize=true" align=middle width=24.08687984999999pt height=22.831056599999986pt/> por edad se toman de [11].

## Estimación de los tiempos de residencia

Para eso usamos la EOD2012.







Liu, Magal, Seydi y Webb plantean un modelo [^1] que permite separar a los casos no reportados de los reportados. Mientras que estos últimos entran en cuarentena, los primeros tienen un rol mucho más dinámico.

Denotando respectivamente <img src="/tex/2389efc1641464f59bc1b58bcab6bb3d.svg?invert_in_darkmode&sanitize=true" align=middle width=66.17218409999998pt height=22.465723500000017pt/> a los individuos susceptibles, infectados que no presentan aún síntomas (por estar en etapa de incubaciónn), infectados reportados e infectados no reportados (“unreported”, ya sea asintomáticos o de baja sintomaticidad), plantean el siguiente diagrama de flujo:

  
![enter image description here](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSIGetCvj7YssWyzkB1lbSVmaXh4tqfLVOsiA&usqp=CAU)


  
## Un resultado teórico
**Teorema:** En situación de pandemia, ie, <img src="/tex/7f8b377d58fdae2f996d053af4935ffc.svg?invert_in_darkmode&sanitize=true" align=middle width=85.89593264999998pt height=22.465723500000017pt/>, y partiendo de condiciones iniciales <img src="/tex/57d86a01ea63e4cb2768866406c87b03.svg?invert_in_darkmode&sanitize=true" align=middle width=156.93311699999998pt height=22.465723500000017pt/> y <img src="/tex/dd7851d03814ba4b0afec01ed57ca5b0.svg?invert_in_darkmode&sanitize=true" align=middle width=97.09200764999999pt height=33.20539859999999pt/> (<img src="/tex/c91091e68f0e0113ff161179172813ac.svg?invert_in_darkmode&sanitize=true" align=middle width=10.28535419999999pt height=14.15524440000002pt/> es un parámetro positivo que explicitan después), se cumple

1. Para cada <img src="/tex/ec2b6a3dd78e3d7ba87ab5db40c09436.svg?invert_in_darkmode&sanitize=true" align=middle width=36.07293689999999pt height=21.18721440000001pt/>, tanto <img src="/tex/fefe6d8e4145041a74f477aca27ddf9f.svg?invert_in_darkmode&sanitize=true" align=middle width=141.97153079999998pt height=24.65753399999998pt/> existen, son positivos, estrictamente menores a <img src="/tex/a9d23346814489213fd836fd320ec0f3.svg?invert_in_darkmode&sanitize=true" align=middle width=131.49738524999998pt height=22.465723500000017pt/> (población total).
2. <img src="/tex/e44fde0f0070cfc63115cab89edb9c6d.svg?invert_in_darkmode&sanitize=true" align=middle width=29.74891424999999pt height=24.65753399999998pt/> converge a cierto valor límite positivo <img src="/tex/6c82a020eaa9b1a97ffe620aa984dc90.svg?invert_in_darkmode&sanitize=true" align=middle width=23.185007999999986pt height=22.465723500000017pt/> cuando <img src="/tex/184f63690975f996187dad1f21c50ca7.svg?invert_in_darkmode&sanitize=true" align=middle width=47.945101049999984pt height=20.221802699999984pt/>, mientras que <img src="/tex/ff2feff301e7507a325ac864e5a9e45e.svg?invert_in_darkmode&sanitize=true" align=middle width=48.752163899999985pt height=22.465723500000017pt/>
convergen a <img src="/tex/29632a9bf827ce0200454dd32fc3be82.svg?invert_in_darkmode&sanitize=true" align=middle width=8.219209349999991pt height=21.18721440000001pt/>.
3. <img src="/tex/e53dba23c14961e2a4017eea668e669c.svg?invert_in_darkmode&sanitize=true" align=middle width=71.28668085pt height=24.65753399999998pt/> converge a <img src="/tex/b27bff3b8fa778ed8b605e0fb7ed9699.svg?invert_in_darkmode&sanitize=true" align=middle width=38.38676159999999pt height=24.65753399999998pt/> por abajo.

## Cosas Interesantes
J. Riou, A. Hauser, M. J. Counotte, and C. L. Althaus. Adjusted age-specific case fatality ratio during
the covid-19 epidemic in hubei, china, january and february 2020. medRxiv, 2020. URL: https://www.
medrxiv.org/content/10.1101/2020.03.04.20031104v1?versioned=true.

### Reportes de movilidad de Google
[https://www.google.com/covid19/mobility/](https://www.google.com/covid19/mobility/) 


[^1]: Zhihua Liu, Pierre Magal, Ousmane Seydi & Glenn Webb. Understanding unreported cases in the COVID-19 epidemic outbreak in Wuhan, China, and the importance of major public health interventions.

[^2]: Andrés Navas & Gastón Vergara-Hermosilla. Observaciones sobre la dinámica de la epidemia de Coronavirus y los casos no reportados: el caso de Chile.

[^3]: Derdei Bichara, Yun Kang, Carlos Castillo-Chavez, Richard Horan, Charles Perrings. SIS and SIR Epidemic Models Under Virtual Dispersal.
[^4]: Reporte 5 - Scenarios for the opening schools during the chilean covid-19 outbreak.


# Referencias, aportes...
Mostrar ecuaciones de <img src="/tex/87181ad2b235919e0785dee664166921.svg?invert_in_darkmode&sanitize=true" align=middle width=45.69716744999999pt height=22.465723500000017pt/> en el README.md de GitHub no está permitido, por lo que usé [TeXify](https://github.com/apps/texify), basándome en [esta respuesta en Stack Overflow](https://stackoverflow.com/a/53981118).
