class_name AbilityData
extends Resource
## Datos de una habilidad (por ejemplo el dash). A diferencia de los objetos (corazón, bomba),
## la habilidad no se elige con E: se usa con su propia tecla (Shift izquierdo) y tiene su
## propio espacio en el HUD, abajo a la izquierda.

## Qué hace la habilidad al usarse.
enum Kind { DASH }

## Nombre que se muestra en el HUD.
@export var display_name: String = "Habilidad"
## Imagen de la habilidad (suelo y HUD). No hace falta recortarla: get_icon() quita los bordes transparentes.
@export var icon: Texture2D
## Tipo de habilidad.
@export var kind: Kind = Kind.DASH
## Segundos de espera entre un uso y el siguiente.
@export var cooldown: float = 3.5

@export_group("Dash")
## Distancia del impulso en píxeles (solo DASH).
@export var dash_distance: float = 260.0
## Duración del impulso en segundos (solo DASH). Menos tiempo = más brusco.
@export var dash_duration: float = 0.16
## Si es true, el jugador no recibe daño mientras dura el impulso (solo DASH).
@export var dash_invulnerable: bool = true

var _icon_cache: Texture2D


## Imagen para mostrar la habilidad, recortada a su contenido.
func get_icon() -> Texture2D:
	if _icon_cache == null:
		_icon_cache = _crop_to_content(icon)
	return _icon_cache


## Recorta los bordes transparentes de la textura.
func _crop_to_content(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return tex
	var used: Rect2i = img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return tex
	var cropped := AtlasTexture.new()
	cropped.atlas = tex
	cropped.region = Rect2(Vector2(used.position), Vector2(used.size))
	return cropped
