class_name Bomb
extends Node2D
## Bomba lanzable: vuela hasta el punto objetivo, explota y hace daño en área.
## Daña a todo lo que tenga take_damage() dentro del radio (menos al jugador).

## Capas de física que la explosión puede golpear (por defecto todas).
@export_flags_2d_physics var hit_mask: int = 0xFFFFFFFF

## Animaciones que se buscan en el AnimatedSprite2D (se usa la primera que exista).
const FLY_ANIMATIONS: Array[String] = ["fly", "throw", "idle", "default", "bomb"]
const EXPLODE_ANIMATION: String = "explode"
## Duración mínima del destello de la explosión (segundos).
const MIN_BLAST_TIME: float = 0.35
## La imagen de la explosión se escala a (radio x 2 x este factor) píxeles.
const EXPLOSION_FIT: float = 2.3

## Tamaño en pantalla (px) de la celda de la bomba en vuelo.
## El dibujo ocupa ~la mitad de la celda, así que 80 deja la bomba de ~36 px.
@export var fly_display_size: float = 80.0

var _damage: int = 1
var _radius: float = 120.0
var _thrower: Node = null
var _exploded: bool = false
## Intensidad del destello circular (1 = recién explotó, 0 = apagado).
var _flash: float = 0.0:
	set(value):
		_flash = value
		queue_redraw()

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


## Configura la bomba y empieza el vuelo hacia target.
func setup(target: Vector2, speed: float, damage: int, radius: float, thrower: Node) -> void:
	_damage = damage
	_radius = radius
	_thrower = thrower
	_play_fly_animation()

	var travel_time: float = maxf(0.05, global_position.distance_to(target) / maxf(speed, 1.0))
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, travel_time)
	tween.tween_callback(_explode)


func _play_fly_animation() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for anim_name in FLY_ANIMATIONS:
		if frames.has_animation(anim_name):
			_fit_sprite(anim_name, fly_display_size)
			sprite.play(anim_name)
			return
	var all_names := frames.get_animation_names()
	if all_names.size() > 0:
		_fit_sprite(all_names[0], fly_display_size)
		sprite.play(all_names[0])


## Escala el sprite para que la celda de la animación mida target_size píxeles.
## Así cada hoja de sprites puede tener su propio tamaño de imagen.
func _fit_sprite(anim_name: StringName, target_size: float) -> void:
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim_name, 0)
	if tex == null:
		return
	var tex_size: Vector2 = tex.get_size()
	sprite.scale = Vector2.ONE * (target_size / maxf(tex_size.x, tex_size.y))


func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	_damage_area()

	# Animación de explosión (si existe) y destello circular que se desvanece.
	var blast_time: float = MIN_BLAST_TIME
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(EXPLODE_ANIMATION):
		var frames: SpriteFrames = sprite.sprite_frames
		_fit_sprite(EXPLODE_ANIMATION, _radius * 1 * EXPLOSION_FIT)
		sprite.play(EXPLODE_ANIMATION)
		var anim_time: float = frames.get_frame_count(EXPLODE_ANIMATION) / maxf(frames.get_animation_speed(EXPLODE_ANIMATION), 1.0)
		blast_time = maxf(blast_time, anim_time)

	_flash = 0.5
	var tween := create_tween()
	tween.tween_property(self, "_flash", 0.0, blast_time)
	tween.tween_callback(queue_free)


## Busca todos los cuerpos dentro del radio y les aplica el daño.
func _damage_area() -> void:
	var shape := CircleShape2D.new()
	shape.radius = _radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = hit_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 64)
	var already_hit: Dictionary = {}  # un cuerpo con varias colisiones solo recibe el daño una vez
	for hit in hits:
		var target: Object = hit.collider
		if already_hit.has(target):
			continue
		already_hit[target] = true
		if target == _thrower or target is Player:
			continue  # la bomba no daña al jugador
		if target != null and target.has_method("take_damage"):
			target.take_damage(_damage)


func _draw() -> void:
	if _flash <= 0.0:
		return
	draw_circle(Vector2.ZERO, _radius, Color(1.0, 0.6, 0.1, 0.30 * _flash))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.3, _flash), 3.0)
