class_name ConsumableData
extends Resource
## Datos de un objeto usable (ej. el corazón): cura y tiene cooldown entre usos.

## Nombre que se muestra (HUD, mensajes).
@export var display_name: String = "Corazón"
## Imagen del objeto (suelo e inventario).
@export var icon: Texture2D
## Vida que cura cada vez que se usa.
@export var heal_amount: int = 1
## Segundos de espera entre un uso y el siguiente.
@export var cooldown: float = 10.0
