class_name Bullet
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: int = 1
var shooter: Node = null   # quién la disparó
var shooter_is_enemy: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(dir: Vector2, spd: float, dmg: int, lifetime: float, from: Node = null) -> void:
	direction = dir
	speed = spd
	damage = dmg
	shooter = from
	shooter_is_enemy = from != null and from.is_in_group("enemy")
	rotation = dir.angle()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	# Sin fuego amigo: las balas de un enemigo atraviesan a otros enemigos
	if shooter_is_enemy and body.is_in_group("enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
