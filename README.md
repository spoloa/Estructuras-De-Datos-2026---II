# Estructuras de Datos 2026-II — Proyecto final: Roguelike en Godot

**Universidad Nacional de Colombia**
Estudiantes: Sebastián Polo Alvarez - Nicolas Morales Lara - Gabriel Yopassa Angulo
**Docente**: Jonatan Perdomo Gomez

---

## Descripción general

Bienvenido a la patria milagro es un videojuego 2D de acción en tiempo real tipo *roguelike* (inspirado en *The Binding of Isaac*), desarrollado en **Godot** con **GDScript** como proyecto para la asignatura Estructuras de Datos. El jugador se mueve por la sala, apunta con el mouse, dispara y sobrevive a oleadas de enemigos que lo persiguen o le disparan.

El objetivo del proyecto no es solo el juego, sino **integrar estructuras de datos lineales implementadas desde cero** en mecánicas reales:

| Estructura | Dónde se usa en el juego |
|---|---|
| Arreglo dinámico (`DynamicArray`) | Inventario de armas del jugador |
| Cola (`Queue`) | Orden en que se lanzan las oleadas de enemigos |
| Cola con prioridad (`PriorityQueue`) | Orden de aparición de los enemigos dentro de cada oleada |
| Pila (`Stack`) | Pantallas de menú abiertas (pausa, opciones), manejadas por `ScreenManager` |

---

## Requisitos

- **Godot [4.7.2]** (versión estándar, no hace falta .NET/Mono). Descarga: https://godotengine.org/download
- No requiere instalar nada más.

---

## Cómo descargar el proyecto

**Opción 1 — Clonar el repositorio (si tienes Git):**
```bash
git clone https://github.com/spoloa/Estructuras-De-Datos-2026---II.git
cd Estructuras-De-Datos-2026---II
```

**Opción 2 — Descargar manualmente:**
En la página del repositorio haz clic en `Code → Download ZIP`, descomprime la carpeta y entra a ella.

---

## Cómo ejecutar el juego

1. Abre Godot y en el administrador de proyectos pulsa **Importar**.
2. Selecciona el archivo `project.godot` de la carpeta del proyecto.
3. Abre el proyecto y pulsa **F5** (Ejecutar proyecto).

> Las instrucciones de juego (controles, enemigos, objetos) están en el [manual de usuario](manual_usuario.md).

### Controles

| Acción | Control |
|---|---|
| Moverse | WASD |
| Apuntar | Mouse |
| Disparar | clic izquierdo |
| Cambiar de arma | Q |
| Pausa / volver al menú anterior | Esc |

---

## Estructuras de datos

Las cuatro estructuras están en la carpeta `scripts/` y están implementadas manualmente (no se usan las estructuras que trae Godot como sustituto). Cada archivo tiene documentación en línea con descripción, complejidad y un ejemplo de uso.

### 1. Arreglo dinámico — `DynamicArray`

**Por qué:** el jugador puede recoger armas durante la partida, así que no se sabe de antemano cuántas tendrá. Un arreglo de tamaño fijo se queda corto o desperdicia memoria.

**Cómo:** arreglo interno con capacidad que crece automáticamente cuando se llena y se reduce cuando queda casi vacío. El jugador guarda sus armas en `inventory` y cambia de arma recorriendo las posiciones con `get_at(slot)`.

**Archivos:** `scripts/DynamicArray.gd` (estructura) y `scripts/Player.gd` (uso).

### 2. Cola — `Queue`

**Por qué:** las oleadas deben lanzarse exactamente en el orden en que se programaron (la primera en entrar es la primera en salir). La cola garantiza ese orden: solo se puede sacar la oleada del frente, así que no es posible saltarse una.

**Cómo:** arreglo con un índice de cabeza (`_head`). Así `dequeue()` es O(1) amortizado, en lugar de O(n) que costaría quitar el primer elemento de un arreglo y desplazar todo. Cuando más de la mitad del arreglo son espacios ya consumidos, se compacta.

**Uso en el juego:** `WaveManager` tiene una `Queue` llamada `waves`. Cada elemento de la cola es una oleada, descrita con un diccionario de Godot que indica cuántos enemigos de cada tipo salen (por ejemplo `{"chaser": 3, "shooter": 3}`). Cuando una oleada termina, `WaveManager` saca la siguiente con `dequeue()`; cuando la cola queda vacía, el juego emite `all_waves_completed`.

> **Nota sobre el diccionario:** `WaveManager` también usa un `Dictionary` propio de Godot (`_enemies`) para llevar la cuenta de los enemigos vivos de la oleada y evitar contar dos veces al mismo enemigo si su señal `died` se emite repetida. Es una herramienta de apoyo del lenguaje; la estructura de datos que ordena las oleadas es la `Queue`.

**Archivos:** `scripts/Queue.gd` (estructura) y `scripts/WaveManager.gd` (uso).

### 3. Cola con prioridad — `PriorityQueue`

**Por qué:** dentro de una oleada no todos los enemigos aparecen en el orden en que se registraron: se quiere que salgan primero los más importantes (por ejemplo, los que persiguen al jugador antes que los que disparan). Una cola normal no permite esto, porque respeta el orden de llegada y no la importancia.

**Cómo:** **montículo binario (heap)** guardado en un arreglo. Para el nodo en la posición `i`, su padre está en `(i - 1) / 2` y sus hijos en `2i + 1` y `2i + 2`. Al insertar, el elemento "sube" hasta su lugar (`_sift_up`); al extraer, el último elemento pasa a la raíz y "baja" (`_sift_down`). Sale primero el de **mayor prioridad**, y si dos tienen la misma, sale primero el que entró antes (desempate estable con un contador de inserción).

**Uso en el juego:** al empezar cada oleada, `WaveManager` mete a la cola cada enemigo con la prioridad de su tipo (`chaser` = 2, `shooter` = 1) y los va sacando para hacerlos aparecer, con una pausa entre cada uno.

**Archivos:** `scripts/PriorityQueue.gd` (estructura) y `scripts/WaveManager.gd` (uso).

### 4. Pila — `Stack`

**Por qué:** los menús se abren uno encima del otro (juego → pausa → opciones) y se cierran en orden inverso: el último menú abierto es el primero en cerrarse (LIFO). Además, una misma pantalla se puede abrir desde varios lugares y "Volver" debe regresar a donde estaba el jugador. Con una pila, "Volver" siempre es un `pop()`, sin programar a mano a dónde vuelve cada botón, y agregar una pantalla nueva no obliga a modificar las demás.

**Cómo:** arreglo interno donde `push()` agrega al tope y `pop()` quita del tope, ambas en O(1).

**Uso en el juego:** `ScreenManager` (Autoload) guarda en una `Stack` las pantallas abiertas. Con **Esc**, si no hay ningún menú abierto se apila el menú de pausa y el juego se pausa; si ya hay uno, se hace `pop()` y se vuelve al anterior. Cuando la pila queda vacía, el juego se reanuda. La pantalla de abajo se oculta, no se destruye, así que al volver aparece tal como estaba. Cada cambio imprime en la consola el tamaño de la pila, lo que sirve para ver cómo crece y decrece.

**Archivos:** `scripts/Stack.gd` (estructura) y `scripts/ScreenManager.gd` (uso, registrado como Autoload en `Proyecto > Configuración del proyecto > Globales`).

---

## Pruebas

El proyecto incluye un script de pruebas automáticas de las estructuras: res://scripts/data_structures/test_structures.gd.

```
--- Resultado: N OK, 0 fallos ---
```

| Estructura | Qué se verifica |
|---|---|
| Stack | Nueva está vacía, `peek` devuelve el tope, `pop` en orden inverso, `size`, y devuelve `null` si está vacía |
| Queue | Respeta el orden FIFO (incluso con compactación), `size`, `peek`, `clear` y devuelve `null` si está vacía |
| PriorityQueue | Sale primero la mayor prioridad, desempate por orden de llegada, queda vacía al final |
| DynamicArray | Crece automáticamente, `get_at`, `insert`, `remove_at`, `index_of`/`contains`, se reduce al vaciarse, índice inválido devuelve `null` |

---

## Eficiencia

| Estructura | Operación | Complejidad |
|---|---|---|
| DynamicArray | `get_at` | O(1) |
| DynamicArray | `add` | O(1) amortizado |
| DynamicArray | `insert` / `remove_at` | O(n) |
| Stack | `push`, `pop`, `peek`, `size`, `is_empty` | O(1) |
| Queue | `enqueue`, `dequeue`, `peek`, `size`, `is_empty` | O(1) amortizado |
| PriorityQueue | `enqueue`, `dequeue` | O(log n) |
| PriorityQueue | `peek`, `size`, `is_empty` | O(1) |

---

## Estructura del repositorio

```
/
├── README.md
├── manual_usuario.md        Manual de usuario
├── project.godot            Archivo del proyecto de Godot
├── icon.svg
├── scenes/                  Escenas (jugador, enemigos, balas, sala, interfaz, menús)
├── scripts/                 Código GDScript (estructuras de datos y lógica del juego)
├── resources/               Recursos de Godot (por ejemplo, datos de armas)
├── animations/              Animaciones
├── assets/                  Imágenes y demás recursos gráficos
└── Tilesets/                Tilesets de las salas
```

---

## Documentación y entregables

- **Documentación en el código:** cada estructura y cada clase del juego tiene comentarios `##` que se ven en la ayuda de Godot.
- **Manual de usuario:** [manual_usuario.md](manual_usuario.md)
- **Documento explicativo del proyecto:**

---

