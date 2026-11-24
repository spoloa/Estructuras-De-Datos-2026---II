class_name Rocket
extends Area2D
## Cohete de la bazuca: vuela en línea recta y EXPLOTA al chocar con un enemigo o una pared
## (o al agotar su alcance). La explosión hace daño en área.
##
## La explosión reutiliza la escena de la bomba (Bomb.tscn): así comparte su animación
## de explosión y su daño en área. Nunca daña al jugador.

## Escena que hace la explosión (Bomb.tscn).
@export var explosion_scene: PackedScene

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 10
var blast_radius: float = 150.0
var shooter: Node = null  # quién lo disparó (no lo detona)

var _exploded: bool = false
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Misma firma que Bullet.setup(), más el radio de la explosión.
func setup(dir: Vector2, spd: float, dmg: int, lifetime: float, from: Node, radius: float) -> void:
	direction = dir
	speed = spd
	damage = dmg
	shooter = from
	blast_radius = radius
	rotation = dir.angle()
	# Si no choca con nada, explota al final de su alcance.
	get_tree().create_timer(lifetime).timeout.connect(_explode)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_time += delta
	queue_redraw()  # para animar la llama


func _on_body_entered(body: Node) -> void:
	if body == shooter or _exploded:
		return
	# No se puede crear física dentro de un callback de física: se explota en diferido.
	call_deferred("_explode")


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	set_physics_process(false)
	if explosion_scene != null:
		var boom: Bomb = explosion_scene.instantiate()
		get_tree().current_scene.add_child(boom)
		boom.global_position = global_position
		boom.detonate(damage, blast_radius, shooter)
	else:
		push_warning("Rocket: falta asignar explosion_scene (Bomb.tscn)")
	queue_free()


## Dibujo provisional del cohete (no necesita imagen). Cámbialo por un Sprite2D si tienes arte.
func _draw() -> void:
	draw_rect(Rect2(-18, -6, 32, 12), Color(0.55, 0.58, 0.62))          # cuerpo
	draw_rect(Rect2(-18, -6, 8, 12), Color(0.35, 0.37, 0.40))           # base
	draw_colored_polygon(PackedVector2Array([Vector2(14, -6), Vector2(26, 0), Vector2(14, 6)]),
		Color(0.85, 0.15, 0.15))                                         # punta
	var flame: float = 10.0 + 5.0 * sin(_time * 40.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -4), Vector2(-18 - flame, 0), Vector2(-18, 4)]),
		Color(1.0, 0.65, 0.1))                                           # llama
