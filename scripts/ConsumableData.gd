class_name ConsumableData
extends Resource
## Datos de un objeto usable (corazón, bomba...): tiene un efecto y un cooldown propio.
## El cooldown de los objetos es independiente del de las armas.

## Qué hace el objeto al usarse.
enum Effect { HEAL, BOMB }

## Nombre que se muestra en el HUD.
@export var display_name: String = "Objeto"
## Imagen del objeto (suelo y HUD). Si queda vacía y es una bomba, se toma de la animación de la bomba.
## No hace falta recortarla: get_icon() quita solo los bordes transparentes.
@export var icon: Texture2D
## Efecto del objeto.
@export var effect: Effect = Effect.HEAL
## Segundos de espera entre un uso y el siguiente.
@export var cooldown: float = 10.0

@export_group("Curación")
## Vida que cura cada vez que se usa (solo HEAL).
@export var heal_amount: int = 1

@export_group("Bomba")
## Daño de la explosión (solo BOMB).
@export var damage: int = 5
## Radio de la explosión en píxeles (solo BOMB).
@export var blast_radius: float = 140.0
## Velocidad de lanzamiento en píxeles por segundo (solo BOMB).
@export var throw_speed: float = 450.0
## Distancia máxima a la que se puede lanzar, en píxeles (solo BOMB).
@export var max_range: float = 450.0
## Escena de la bomba (Bomb.tscn, solo BOMB).
@export var bomb_scene: PackedScene

var _icon_cache: Texture2D


## Imagen para mostrar el objeto (HUD y suelo), recortada a su contenido.
## Así el corazón y la bomba llenan el mismo espacio aunque sus PNG tengan márgenes distintos.
func get_icon() -> Texture2D:
	if _icon_cache != null:
		return _icon_cache

	var source: Texture2D = icon
	if source == null and bomb_scene != null:
		source = _icon_from_bomb()
	_icon_cache = _crop_to_content(source)
	return _icon_cache


## Primer frame de la animación de la bomba (fly, o la primera que exista).
func _icon_from_bomb() -> Texture2D:
	var instance: Node = bomb_scene.instantiate()
	var anim: AnimatedSprite2D = instance.get_node_or_null("AnimatedSprite2D")
	var frame_tex: Texture2D = null
	if anim != null and anim.sprite_frames != null:
		var frames: SpriteFrames = anim.sprite_frames
		var anim_names := frames.get_animation_names()
		var pick: StringName = &""
		if frames.has_animation(&"fly"):
			pick = &"fly"
		elif anim_names.size() > 0:
			pick = anim_names[0]
		if pick != &"" and frames.get_frame_count(pick) > 0:
			frame_tex = frames.get_frame_texture(pick, 0)
	instance.free()
	return frame_tex


## Recorta los bordes transparentes de cualquier textura (PNG suelto o celda de hoja de sprites).
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
	var atlas_tex := tex as AtlasTexture
	if atlas_tex != null:
		cropped.atlas = atlas_tex.atlas
		cropped.region = Rect2(atlas_tex.region.position + Vector2(used.position), Vector2(used.size))
	else:
		cropped.atlas = tex
		cropped.region = Rect2(Vector2(used.position), Vector2(used.size))
	return cropped
