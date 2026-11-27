class_name DangerZone
extends Node2D
## Zona de peligro: hace daño continuo a quien esté dentro.

@export var damage_per_second: float = 5.0
@export var lifetime: float = 4.0

var _radius: float = 120.0
var _tick_accum: float = 0.0
var _bodies_inside: Array = []

@onready var _area: Area2D = $Area2D
@onready var _shape: CollisionShape2D = $Area2D/CollisionShape2D

func setup(radius: float, dps: float) -> void:
	_radius = radius
	damage_per_second = dps

func _ready() -> void:
	add_to_group("danger_zone")
	var circle := CircleShape2D.new()
	circle.radius = _radius
	_shape.shape = circle
	_area.body_entered.connect(func(b): if not _bodies_inside.has(b): _bodies_inside.append(b))
	_area.body_exited.connect(func(b): _bodies_inside.erase(b))
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	_tick_accum += delta
	if _tick_accum < 1.0:
		return
	_tick_accum -= 1.0
	for b in _bodies_inside:
		if is_instance_valid(b) and b.has_method("take_damage"):
			b.take_damage(int(round(damage_per_second)))
