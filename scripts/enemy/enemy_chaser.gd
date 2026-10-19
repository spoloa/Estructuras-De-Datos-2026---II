class_name EnemyChaser
extends CharacterBody2D

signal died

@export var max_health: int = 6
@export var move_speed: float = 140.0
@export var contact_damage: int = 1
## Segundos entre un golpe y el siguiente.
@export var contact_cooldown: float = 1.0

var health: int
var player: Player = null
var _can_hit := true

@onready var health_bar: ProgressBar = $HealthBar
@onready var contact_area: Area2D = $ContactArea


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	$DetectionArea.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body   # una vez que te ve, te persigue siempre


func _physics_process(_delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
	else:
		velocity = (player.global_position - global_position).normalized() * move_speed
		$AnimatedSprite2D.flip_h = velocity.x < 0
	move_and_slide()
	_check_contact()


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
	health -= amount
	health_bar.value = health
	if health <= 0:
		died.emit()
		queue_free()
