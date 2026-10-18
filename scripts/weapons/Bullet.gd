class_name Bullet
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: int = 1
var shooter: Node = null   # quién la disparó


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(dir: Vector2, spd: float, dmg: int, lifetime: float, from: Node = null) -> void:
	direction = dir
	speed = spd
	damage = dmg
	shooter = from
	rotation = dir.angle()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return  # no golpea a quien la disparó
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
