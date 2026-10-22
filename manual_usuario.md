# Manual de usuario

**Bienvenido a la patria milagro** es un juego de acción en 2D visto desde arriba: te mueves
por una arena, apuntas con el mouse y sobrevives a tres oleadas de enemigos.

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

El juego tiene **3 oleadas**, cada una más grande que la anterior:

| Oleada | Perseguidores | Tiradores | Total |
|---|---|---|---|
| 1 | 2 | 1 | 3 |
| 2 | 3 | 3 | 6 |
| 3 | 4 | 5 | 9 |

- Los enemigos de una oleada aparecen de uno en uno (cada 2.5 s) por dos puntos de aparición;
  **los Perseguidores salen primero** y después los Tiradores.
- Una oleada nueva empieza 6 segundos después de derrotar a todos los enemigos de la anterior.
- Ganas cuando mueren todos los enemigos de la oleada 3.

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
| Corazón | Objeto | Se guarda en tu inventario de objetos. Al usarlo recupera 1 de vida y luego debe recargarse 10 segundos. No se puede usar con la vida llena (así no gastas la recarga). |
| Bomba | Objeto | Se guarda en tu inventario de objetos. Al usarla, la lanzas hacia el cursor (hasta unos 450 píxeles), explota y hace daño en área. Recarga de 15 segundos. |

Los objetos **no se gastan**: el corazón y la bomba se pueden usar una y otra vez, esperando a
que termine su recarga. Solo puedes llevar uno de cada tipo (si ya lo tienes, el del suelo no
se recoge). La recarga de los objetos es independiente de la de las armas: lanzar una bomba
no te impide seguir disparando.

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


