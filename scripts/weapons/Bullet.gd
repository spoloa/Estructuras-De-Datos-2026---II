class_name Bullet
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: int = 1
var shooter: Node = null   # quién la disparó
var shooter_is_enemy: bool = false

## Zona de juego (borde interior de las paredes). Fuera de ella la bala se destruye.
const ARENA := Rect2(-1789, -778, 3862, 2172)
## Una pared solo destruye la bala si ya se alejó esta distancia (px) del punto de disparo.
## Si dispara pegado a la pared, la bala nace tocándola y antes se destruía al instante.
const WALL_GRACE_DISTANCE: float = 60.0

var _start: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(dir: Vector2, spd: float, dmg: int, lifetime: float, from: Node = null) -> void:
	direction = dir
	speed = spd
	damage = dmg
	shooter = from
	shooter_is_enemy = from != null and from.is_in_group("enemy")
	rotation = dir.angle()
	_start = global_position
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	# Respaldo: si salió de la arena (por ejemplo atravesó una pared al disparar pegado a ella) se borra.
	if not ARENA.has_point(global_position):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	# Paredes: se ignoran justo al salir del arma (disparo pegado al borde).
	if body is StaticBody2D and global_position.distance_to(_start) < WALL_GRACE_DISTANCE:
		return
	# Sin fuego amigo: las balas de un enemigo atraviesan a otros enemigos
	if shooter_is_enemy and body.is_in_group("enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
