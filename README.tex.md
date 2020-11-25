# Modelo Lagrangiano con tiempos de residencia

Repositorio de mi trabajo de tesis: un modelo lagrangiano con tiempos de residencia.


# lagrangian-time
Repositorio de mi trabajo de tesis: un modelo lagrangiano con tiempos de residencia.

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
S_i'(t) &=& -S_i(t)\lambda_i(t) \\
E_i'(t) &=& S_i(t)\lambda_i(t) - \gamma_{E} E_i(t) \\
I_i'(t) &=& \phi\gamma_{E} E_i(t) - \gamma_{I} I_i(t) \\
(I_i^{m})'(t) &=& (1-\phi)\gamma_{I} E_i(t) - \gamma_{I^m} I_i^m(t) \\
R_i'(t) &=& \gamma_I I_i(t) + \gamma_{I^m} I_i^m(t)
\end{array}
$$
donde la tasa de contagio $\lambda_i$ se define como sigue.
$$
\lambda_i(t) = \sum_{j=1}^m \beta_{j}p^S_{ij}
\left(
\alpha_E \frac{\sum_{k=1}^{n} p^E_{kj}E_k}{\sum_{k=1}^{n}p^E_{kj}N_k}
+
\alpha_{I} \frac{\sum_{k=1}^{n} p^I_{ kj}I_k }{\sum_{k=1}^{n}p^I_{kj}N_k} +
\alpha_{I^m} \frac{\sum_{k=1}^{n}p^{I^m}_{kj}I^m_k}{\sum_{k=1}^{n}p^{I^m}_{kj}N_k}
\right)
$$

Comparamos con la tasa de contagios que se usaba en el reporte 3 por ejemplo:
$$
\lambda_i(t) = \sum_{j=1}^{n} \frac{\alpha(t)p_EC_{ij}E_{j} + \alpha(t)p_{I^m}C_{ij}I_j^m + \delta_{p_I}C_{ij}I_j}{N_j}
$$



## Matriz de residencia de Infectados
Después de leer un poco más el artículo donde aparece el modelo con tiempos de residencia, veo que tiene razón con separar las fracciones, no estaría bien dejarlas con un denominador común. Con respecto al problema del denominador que se anula, tengo esto:

Supongamos que los infectados detectados $I$ pasan todo el tiempo en su casa, o en un ambiente donde haya bajo riesgo de contagio (Incluso es posible suponer que no contagian, como en el modelo que estudió Andrés Navas). Entonces su matriz de residencia $P^I$ es de la forma 
 $$
 (p^I)_{ij} = \delta_{\text{hogar},j}
 $$
Cuando calculamos los riesgos de contagio en un ambiente $j$, necesitamos la fracción de infectados que está en ese ambiente. Pero ya vimos que los infectados detectados solo pasan tiempo en el ambiente hogar, así que fuera del ambiente hogar no hay probabilidad de ser contagiado por un infectado detectado. En el ambiente hogar, sin embargo, están los infectados detectados de todas las clases, así que ahí la fracción sería 
$$
\frac{
\sum_{i=1}^{\text{total clases}} I_i
}{
\sum_{i=1}^{\text{total clases}} N_i
}
$$

Finalmente, eso deja la tasa de contagios como sigue:
$$
\lambda_i(t) = \sum_{j=1}^m \beta_{j}p^S_{ij}
\left(
\alpha_E \frac{\sum_{k=1}^{n} p^E_{kj}E_k}{\sum_{k=1}^{n}p^E_{kj}N_k}
+
\alpha_{I^m} \frac{\sum_{k=1}^{n}p^{I^m}_{kj}I^m_k}{\sum_{k=1}^{n}p^{I^m}_{kj}N_k}
+
\alpha_{I} \delta_{\text{hogar},j} \frac{\sum_{i=1}^{\text{total clases}} I_i}{\sum_{i=1}^{\text{total clases}} N_i}
\right)
$$

Si lo traducimos a notación matricial (la división aquí corresponde a división por coordenada, y la multiplicación con un $\cdot$ también. Si no hay símbolo es multiplicación de matrices. $\vec{\delta}_i$ es un vector de largo $m$ con 0's en todas sus coordenadas salvo en $i$).

$$
P
\left[
\beta \cdot
\left(
\alpha_E \frac{(P^E)^t E}{(P^E)^t N} + \alpha_{I^m} \frac{(P^{I^m})^t I^m}{(P^{I^m})^t N} +  \alpha_I \vec{\delta}_{\text{hogar}} \frac{\sum_{i=1}^{n} I_i}{\sum_{i=1}^{n} N_i}
\right)
\right]
$$

Si queremos evitar construir un vector de muchos 0's, una forma alternativa es la siguiente

en todas sus coordenadas salvo en $i$).

$$
P
\left[
\beta \cdot
\left(
\alpha_E \frac{(P^E)^t E}{(P^E)^t N} + \alpha_{I^m} \frac{(P^{I^m})^t I^m}{(P^{I^m})^t N} 
\right)
\right]+
\beta_1  \alpha_I \frac{\sum_{i=1}^{n} I_i}{\sum_{i=1}^{n} N_i}
P_{:, \text{hogar}} 
$$

Usamos esta forma alternativa 
```julia
function calcular_lambda!(λ, αₑ, αᵢₘ, β, P, S, E, I, Iᵐ)
    hogar = 1
    N = S + E + I + Iᵐ + R
    λ =  P*(β .* ( αₑ*(P' * E)./(P' * N) + αᵢₘ*(P' * Iᵐ)./(P' * N) ))
    λ += β[1]*(sum(I)/sum(N))*P[:,hogar]
end
```

## Tasa de contagio
En el Reporte 5 [^4] usan matrices de contacto en lugar de tiempos de residencia, pero la idea es interesante. Consideran una matriz de contacto a la que contribuyen varios factores ($\text{w}$ corresponde a trabajo (*work*), $\text{s}$ es escuela (*school*), $\text{h}$ es hogar (*home*) y $\text{o}$ es otros (*other*)).
$$
C = C_\text{w} + C_\text{s} + C_\text{h} + C_\text{o}
$$
Para que esta matriz sea dependiente del tiempo, agregan ponderadores dependientes del tiempo, de tal forma que 
$$
C(t) = (1+ f_\text{w}(t))C_\text{w} +  f_\text{s}(t)C_\text{s} +  (1+ f_\text{h}(t))C_\text{h} +  (1+ f_\text{o}(t))C_\text{o}
$$

En mi caso, no tengo una matriz por ambiente. Más bien, cada una de las columnas de mi matriz corresponde a un ambiente. Así que podría hacer una versión de eso usando el mismo ponderador para cada columna.




## Estimación de parámetros
- Tasas $\phi_\text{HD}$, $\phi_\text{HR}$ and $\phi_\text{HcD}$ y fracción de infectados asintomáticos $\phi_\text{EI}$ por edad [16]:
- [https://www.medrxiv.org/content/10.1101/2020.03.04.20031104v1.full.pdf](https://www.medrxiv.org/content/10.1101/2020.03.04.20031104v1.full.pdf)
- Inverso de los tiempos de duración de cada etapa $\gamma_\text{H}, \gamma_\text{Hc}$ y fracción de infectados que se recupera $\phi_\text{IR}$ por edad se toman de [11].

## Estimación de los tiempos de residencia

Para eso usamos la EOD2012.







Liu, Magal, Seydi y Webb plantean un modelo [^1] que permite separar a los casos no reportados de los reportados. Mientras que estos últimos entran en cuarentena, los primeros tienen un rol mucho más dinámico.

Denotando respectivamente $S, I, R, U$ a los individuos susceptibles, infectados que no presentan aún síntomas (por estar en etapa de incubaciónn), infectados reportados e infectados no reportados (“unreported”, ya sea asintomáticos o de baja sintomaticidad), plantean el siguiente diagrama de flujo:

  
![enter image description here](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSIGetCvj7YssWyzkB1lbSVmaXh4tqfLVOsiA&usqp=CAU)


  
## Un resultado teórico
**Teorema:** En situación de pandemia, ie, $\tau S_0 - \nu > 0$, y partiendo de condiciones iniciales $S_0 > 0, I_0 > 0, R_0 = 0$ y $U_0 = \frac{(1-\phi)\nu I_0}{\eta + \chi}$ ($\chi$ es un parámetro positivo que explicitan después), se cumple

1. Para cada $t>0$, tanto $S(t), I(t), R(t), U(t)$ existen, son positivos, estrictamente menores a $N:= S_0 + I_0 + U_0$ (población total).
2. $S(t)$ converge a cierto valor límite positivo $S_\infty$ cuando $t \to \infty$, mientras que $I, R, U$
convergen a $0$.
3. $R(t)/U(t)$ converge a $\nu_1/\nu_2$ por abajo.

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
Mostrar ecuaciones de $\LaTeX$ en el README.md de GitHub no está permitido, por lo que usé [TeXify](https://github.com/apps/texify), basándome en [esta respuesta en Stack Overflow](https://stackoverflow.com/a/53981118).
