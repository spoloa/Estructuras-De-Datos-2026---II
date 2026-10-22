class_name EnemyChaser
extends CharacterBody2D

signal died

@export var max_health: int = 6
@export var move_speed: float = 140.0
@export var contact_damage: int = 1
## Segundos entre un golpe y el siguiente.
@export var contact_cooldown: float = 1.0
## Si el dibujo original del sprite mira a la IZQUIERDA, déjalo en true.
## Si mira a la DERECHA, ponlo en false.
@export var sprite_faces_left: bool = true

var health: int
var _dead := false  # true en cuanto muere (evita morir dos veces)
var player: Player = null
var _can_hit := true

@onready var health_bar: ProgressBar = $HealthBar
@onready var contact_area: Area2D = $ContactArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	EnemyHealthBar.style(health_bar)
	health_bar.max_value = max_health
	health_bar.value = health
	$DetectionArea.body_entered.connect(_on_body_entered)
	sprite.flip_h = false  # valor inicial al aparecer (sin voltear)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body   # una vez que te ve, te persigue siempre


func _physics_process(_delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
	else:
		velocity = (player.global_position - global_position).normalized() * move_speed
		_update_facing()
	move_and_slide()
	_check_contact()


## Voltea el sprite según el lado hacia el que se mueve.
## La zona muerta evita que parpadee cuando se mueve casi en vertical.
func _update_facing() -> void:
	if absf(velocity.x) <= 5.0:
		return
	var moving_right := velocity.x > 0
	# Si el dibujo mira a la izquierda, hay que voltearlo al ir a la derecha (y viceversa).
	sprite.flip_h = moving_right if sprite_faces_left else not moving_right


func _check_contact() -> void:
	if not _can_hit:
		return
	for body in contact_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(contact_damage)
			_can_hit = false
			await get_tree().create_timer(contact_cooldown).timeout
			_can_hit = true
			return


func take_damage(amount: int) -> void:
	if _dead:
		return  # ya murió: queue_free() no borra al instante, así que sin esto
		# varios golpes en el mismo frame emitirían 'died' y soltarían ítems varias veces
	health -= amount
	health_bar.value = health
	if health <= 0:
		_dead = true
		died.emit()
		ItemDrop.try_drop(self)
		queue_free()
