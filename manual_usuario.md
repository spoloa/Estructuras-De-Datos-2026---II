# Manual de usuario

**Bienvenido a la patria milagro** es un juego de acción en 2D visto desde arriba: te mueves
por una arena, apuntas con el mouse y sobrevives a siete oleadas de enemigos.

## Objetivo

Sobrevive a todas las oleadas de enemigos. Si tu vida llega a 0 pierdes (**GAME OVER**);
si derrotas a todos los enemigos de la última oleada ganas (**¡VICTORIA!**).

## Cómo empezar

1. Al abrir el juego aparece el **menú principal**.
2. **Jugar** inicia la partida.
3. **Controles** muestra u oculta la lista de teclas.
4. **Salir** cierra el juego.

Durante la partida suena una música de fondo. Su volumen se cambia desde el menú de pausa
(**Opciones**).

## Controles

| Acción | Tecla |
|---|---|
| Moverse | W, A, S, D |
| Disparar | Clic izquierdo (la bala sale hacia el cursor) |
| Usar el objeto seleccionado | Clic derecho (la bomba se lanza hacia el cursor) |
| Cambiar de arma | Q |
| Cambiar de objeto | E |
| Habilidad (dash) | Shift izquierdo |
| Abrir / cerrar las mejoras | U |
| Pausa / volver atrás en un menú | Esc |

Tu personaje mira hacia donde está el cursor, que es hacia donde dispara.

## Pantalla de juego (HUD)

El HUD tiene un estilo retro con marcos dorados y paneles semitransparentes, para que se
vea el escenario detrás:

- **Barra de vida (arriba a la izquierda):** barra roja con un corazón y el número de corazones
  dentro (por ejemplo `3 / 5`; empiezas con 5). Se anima al recibir daño o curarte y
  destella cuando te golpean.
- **Arma (debajo de la vida):** nombre del arma equipada y una casilla por cada arma de tu
  inventario; la casilla dorada es la que tienes equipada. Cambias de arma con **Q**.
- **Objeto (debajo del arma):** muestra el objeto seleccionado (corazón o bomba) con su icono,
  su nombre y una **barra de recarga** que se llena mientras el objeto no se puede usar. El
  icono se oscurece y aparece el tiempo que falta (por ejemplo `4.2s`); cuando está listo
  dice **LISTO**. Una casilla por cada objeto que llevas indica cuál está seleccionado
  (la dorada). Si no tienes ninguno, el panel dice **VACÍO**. Cambias de objeto con **E**.
- **Oleada (arriba a la derecha):** oleada actual / total de oleadas. Al terminar todas
  muestra **¡LISTO!**.
- **XP (arriba a la derecha, debajo de los puntos):** la experiencia que llevas para comprar mejoras, con el recordatorio `[U] MEJORAS`.
- **Avisos:** en el centro aparece un mensaje grande que se desvanece solo: **¡PREPÁRATE!**
  al empezar, **¡OLEADA 2!** al comenzar cada oleada y, al recoger un objeto, el nombre del
  objeto con las teclas para usarlo.

## Enemigos

Cada enemigo tiene una **barra de salud** roja sobre su cabeza que se vacía al recibir daño.

| Enemigo | Vida | Comportamiento |
|---|---|---|
| Perseguidor (Costeño) | 20 | Corre hacia ti (rápido) y te quita 1 de vida al tocarte, como máximo una vez por segundo. |
| Tirador (Freud Boy) | 15 | Se acerca, se detiene a unos 200 píxeles y te dispara con una escopeta: 5 perdigones dispersos, cada uno quita 1 de vida. Necesita verte para disparar (no dispara a través de las paredes). |

Los enemigos empiezan a perseguirte cuando entras en su rango de detección y ya no te
sueltan.

### Oleadas

El juego tiene **7 oleadas**, cada una más larga que la anterior. La **oleada 5 es la más difícil**:
sale casi una avalancha de enemigos.

| Oleada | Perseguidores | Tiradores | Total | Aparición |
|---|---|---|---|---|
| 1 | 4 | 2 | 6 | cada 2.5 s |
| 2 | 6 | 4 | 10 | cada 2.5 s |
| 3 | 8 | 6 | 14 | cada 2.5 s |
| 4 | 10 | 8 | 18 | cada 2.5 s |
| 5 | 18 | 14 | 32 | cada 1 s |
| 6 | 10 | 8 | 18 | cada 2.5 s |
| 7 | 14 | 12 | 26 | cada 1.5 s |

- Los enemigos de una oleada aparecen de uno en uno por dos puntos de aparición;
  **los Perseguidores salen primero** y después los Tiradores.
- Todos salen sabiendo dónde estás: te persiguen desde que aparecen.
- Si un enemigo se queda atorado lejos de ti más de 6 segundos, se le cambia de lugar a un punto de aparición para que la oleada no se trabe.
- Los enemigos no aparecen mientras el juego está en pausa (por ejemplo, con la pantalla de mejoras abierta).
- Una oleada nueva empieza 6 segundos después de derrotar a todos los enemigos de la anterior.
- Ganas cuando mueren todos los enemigos de la oleada 7.

## Ítems

Los enemigos pueden soltar ítems al morir. Camina sobre ellos para recogerlos. Al morir un
enemigo se tira un dado:

| Resultado | Probabilidad |
|---|---|
| Escopeta | 20 % |
| Bomba | 20 % |
| Corazón | 25 % |
| Nada | 35 % |

| Ítem | Tipo | Efecto |
|---|---|---|
| Escopeta | Arma | Se agrega a tu inventario de armas (si ya la tienes no se recoge). |
| Dash | Habilidad | Se usa con Shift izquierdo. Solo se recoge una vez. |
| Corazón | Objeto | Suma 1 unidad a tu pila de corazones. Al usar uno recupera 1 de vida y luego debe recargarse 10 segundos. No se puede usar con la vida llena (así no gastas la unidad ni la recarga). |
| Bomba | Objeto | Suma 1 unidad a tu pila de bombas. Al usar una, la lanzas hacia el cursor (hasta unos 450 píxeles), explota y hace daño en área. Recarga de 15 segundos. |

Los corazones y las bombas **se apilan y se gastan**: cada vez que usas uno pierdes una unidad
(el HUD muestra por ejemplo `CORAZÓN x3`). Puedes llevar hasta 9 de cada uno; si ya llevas 9, el del
suelo no se recoge. Aunque tengas varias unidades, entre un uso y otro hay que esperar la recarga.
Si te quedas en 0 el panel dice **SIN UNIDADES** hasta que recojas otro. La recarga de los objetos es
independiente de la de las armas: lanzar una bomba no te impide seguir disparando.

Las **armas y el dash no se repiten**: no se suelta una si ya la tienes o si ya hay una igual
en el suelo, y al recogerla desaparecen las demás copias que hubiera.

## Armas

Empiezas la partida con la **Pistola**.

| Arma | Daño | Cadencia | Característica |
|---|---|---|---|
| Pistola | 2 | 2 disparos por segundo | Disparo único, bala rápida y de largo alcance. |
| Escopeta | 2 por perdigón | 1 disparo cada 2 segundos | 5 perdigones por disparo con dispersión; alcance corto. Se encuentra en el suelo. |

Cambia entre tus armas con **Q**. Mantén presionado el clic izquierdo para disparar de forma
continua; el arma dispara sola según su cadencia.

## Objetos

| Objeto | Efecto | Recarga |
|---|---|---|
| Corazón | Cura 1 de vida. | 10 s |
| Bomba | Explosión de 200 píxeles de radio: 15 de daño a todos los enemigos dentro del área (no te daña a ti). Mata a un Tirador (15 de vida) de un solo golpe y deja al Perseguidor (20 de vida) casi muerto. | 15 s |

Cambia de objeto con **E** y úsalo con el **clic derecho**. La bomba vuela hasta el punto
donde está el cursor (con un alcance máximo), muestra una animación de explosión y desaparece.

## XP y mejoras

Cada enemigo suelta **XP** al morir (aparece un `+N XP` flotando donde cayó). La cantidad es
un número al azar dentro de un intervalo, y los tiradores dan más que los perseguidores:

| Enemigo | XP al morir |
|---|---|
| Perseguidor | de 3 a 6 |
| Tirador | de 6 a 12 |

Con **U** se abre la pantalla de **Mejoras** (el juego queda en pausa; **U**, **Esc** o **Cerrar** la cierran).
Tiene dos mini ventanas:

- **Tus mejoras (izquierda):** una casilla por cada arma, objeto y habilidad que tienes, con tres
  casillitas que indican tu nivel (1 a 3). Pasa el mouse sobre una casilla para ver sus
  estadísticas actuales y las mejoras que ya compraste.
- **Árbol de mejoras (derecha):** todas las mejoras posibles. Cada arma, objeto y habilidad tiene
  **3 niveles**: el nivel 1 es el base (el que ya existe) y los niveles 2 y 3 se compran con XP.
  Un nivel solo se puede comprar si ya tienes el anterior (y, para el nivel 2, si ya tienes el
  objeto). Colores: dorado = ya la tienes, azul = puedes comprarla, rojo = te falta XP,
  gris = bloqueada. Haz clic en una mejora azul para comprarla.

Las mejoras duran lo que dura la partida: al empezar otra, vuelves a tener 0 XP y todo en nivel 1.

## Menú de pausa

Con **Esc** se abre la pausa y el juego se detiene:

- **Continuar:** vuelve a la partida.
- **Opciones:** abre un menú encima de la pausa con un control de **volumen**; **Volver** regresa a la pausa.
- **Salir del juego:** cierra el juego.

Esc siempre te lleva un paso atrás: desde opciones vuelves a la pausa y desde la pausa a la partida.
En el menú principal y en la pantalla final Esc no abre la pausa.

## Fin de la partida

Al ganar (**¡VICTORIA!**) o perder (**GAME OVER**) aparece, tras una breve pausa para ver
el último momento, una pantalla con tres opciones:

- **Reintentar:** empieza la partida de nuevo.
- **Menú principal:** vuelve al menú de inicio.
- **Salir del juego.**

## Consejos

- Prioriza a los **Perseguidores**: son rápidos y te golpean al contacto.
- Con la **Escopeta** acierta más de cerca; con la **Pistola** puedes disparar de lejos.
- Guarda la **bomba** para cuando haya varios enemigos juntos: hace 15 de daño en área.
- Usa el **corazón** cuando te falte vida; con la vida llena no se puede usar.
- Los **Tiradores** no pueden dispararte si hay una pared de por medio: úsala de cobertura.
