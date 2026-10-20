class_name EnemyBullet
extends Area2D
## Proyectil enemigo: daña al jugador. Atraviesa a otros enemigos y desaparece
## al chocar con cualquier obstáculo (cuerpo que no puede recibir daño, como una pared).

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Configura el proyectil. Lo llama el enemigo que dispara.
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
		body.take_damage(damage)
		queue_free()
	elif not body.has_method("take_damage"):
		queue_free()  # chocó con una pared u obstáculo
	# si es otro enemigo (tiene take_damage), lo atraviesa
