# lagrangian-time
Repositorio de mi trabajo de tesis: un modelo lagrangiano con tiempos de residencia.

Para mostrar adecuadamente esta pagina es posible usar el plugin [MathJax Plugin for Github](https://chrome.google.com/webstore/detail/mathjax-plugin-for-github/ioemnmodlmafdkllaclgeombjnmnbima/related).

## Modelo
En el contexto de modelar la epidema por coronavirus y enfrentar 
Una dificultad a la hora de modelar la epidemia por COVID-19 es la falta de datos de calidad. Debido a la imposibilidad de realizar test a toda la población, el número de individuos contagiados es mayor al real, especialmente en los pacientes asíntomáticos. Liu, Magal, Seydi y Webb plantean [^1] un modelo $(1)$ que permite separar a los casos no reportados de los reportados. Mientras que estos últimos entran en cuarentena, los primeros tienen un rol mucho más dinámico.

$$
(1) \quad
\left\{
\begin{array}{rcl}
S'(t) &=& -\tau S(t) [I(t) + U(t)] \\
I'(t) &=&-\tau S(t) [I(t) + U(t)] - \nu I(t) \\
R'(t) &=& \phi \nu I(t) - \eta R(t) \\
U'(t) &=& (1-\phi) \nu I(t) - \eta U(t)
\end{array}
\right.
$$

Este modelo ha sido estudiado teóricamente y aplicado al caso de Chile[^2]. Nos interesa utilizarlo con un enfoque lagrangiano, considerando el tiempo invertido por diferentes grupos sociales (separados por edad, sexo, etc) en varios ambientes (escuela, hogar, trabajo, etc), como plantea [^3].

Más específicamente, separamos a la población en $n$ clases, las cuales interactúan en $m$ ambientes (o áreas de riesgo). Denotamos por $N_i(t), i = 1, \dots, n$ a la cantidad de individuos de la clase $i$. Suponemos que la población de la clase $i$ pasa una proporción $p_{ij} \in [0,1]$ de su tiempo en el ambiente $j$, con $\sum_{j = 1}^{m} p_{ij} = 1$ para cada $i$. Para casos extremos, por ejemplo, podría darse que $p_{ij} = 0$, es decir, la clase $i$ no gasta nada de su tiempo en el ambiente $j$, mientras que $p_{ij} = 1$ significa que la clase $i$ pasa todo su tiempo en el ambiente $j$. Esto nos permite plantear el siguiente modelo:

$$
\begin{array}{rcl}
S_i'(t) &=& -S_i(t)\lambda(t) \\
E_i'(t) &=& S_i(t)\lambda - \nu_i E_i(t) \\
I_i'(t) &=& \phi\nu_i E_i(t) - \gamma_i I_i(t) \\
(I_i^{m})'(t) &=& (1-\phi)\nu_i E_i(t) - \gamma^m_{i} I_i^m(t) \\
R_i'(t) &=& \gamma_i I_i(t) + \gamma^m_{i} I_i^m(t)
\end{array}
$$
donde la tasa de contagio $\lambda_i$ se define como sigue.
$$
\lambda_i(t) = \sum_{j=1}^m \beta_{ij}p^S_{ij}
\left(
\frac{\sum_{k=1}^{n}\alpha p^E_{kj}E_k}{\sum_{k=1}^{n}p^E_{kj}N_k}
+
\frac{\sum_{k=1}^{n} p^I_{ kj}I_k }{\sum_{k=1}^{n}p^I_{kj}N_k} +
\frac{\sum_{k=1}^{n}p^{I^m}_{kj}I^m_k}{\sum_{k=1}^{n}p^{I^m}_{kj}N_k}
\right)
$$

## Estimación de los tiempos de residencia

Para eso usamos la EOD2012.





[^1]: Zhihua Liu, Pierre Magal, Ousmane Seydi & Glenn Webb. Understanding unreported cases in the COVID-19 epidemic outbreak in Wuhan, China, and the importance of major public health interventions.

[^2]: Andrés Navas & Gastón Vergara-Hermosilla. Observaciones sobre la dinámica de la epidemia de Coronavirus y los casos no reportados: el caso de Chile.

[^3]: Derdei Bichara, Yun Kang, Carlos Castillo-Chavez, Richard Horan, Charles Perrings. SIS and SIR Epidemic Models Under Virtual Dispersal.
