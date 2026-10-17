class_name Bullet
extends Area2D
## Proyectil: avanza en línea recta, hace daño al chocar y desaparece.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Configura el proyectil con los datos del arma que lo disparó.
func setup(dir: Vector2, spd: float, dmg: int, lifetime: float) -> void:
	direction = dir
	speed = spd
	damage = dmg
	rotation = dir.angle()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body is Player:
		return  # el proyectil no golpea a quien lo disparó
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
