class_name Enemy
extends CharacterBody2D

signal died

@export var max_health: int = 100
@export var bullet_scene: PackedScene      # arrastra Bullet.tscn
@export var weapon: WeaponData             # arrastra el recurso de la escopeta
@export var aim_delay: float = 0.4         # pausa antes de disparar (aviso al jugador)

var health: int
var player: Player = null
var can_shoot := true

@onready var health_bar: ProgressBar = $HealthBar
@onready var ray: RayCast2D = $RayCast2D
@onready var muzzle: Marker2D = $Muzzle
@onready var cooldown: Timer = $ShootCooldown


func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	$DetectionArea.body_entered.connect(_on_body_entered)
	$DetectionArea.body_exited.connect(_on_body_exited)
	cooldown.timeout.connect(func(): can_shoot = true)
	if weapon:
		cooldown.wait_time = 1.0 / weapon.fire_rate


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


func _physics_process(_delta: float) -> void:
	if player and can_shoot and _can_see_player():
		_shoot_at_player()


func _can_see_player() -> bool:
	ray.target_position = ray.to_local(player.global_position)
	ray.force_raycast_update()
	return ray.is_colliding() and ray.get_collider() == player


func _shoot_at_player() -> void:
	if weapon == null or bullet_scene == null:
		push_warning("Enemy: falta asignar Weapon o Bullet Scene")
		return
	can_shoot = false
	var target := player.global_position
	await get_tree().create_timer(aim_delay).timeout
	cooldown.start()
	var base_dir := (target - muzzle.global_position).normalized()
	for i in weapon.bullets_per_shot:
		var angle := deg_to_rad(randf_range(-weapon.spread_degrees, weapon.spread_degrees))
		var bullet: Bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = muzzle.global_position
		bullet.setup(base_dir.rotated(angle), weapon.bullet_speed, weapon.damage, weapon.bullet_lifetime, self)


func take_damage(amount: int) -> void:
	health -= amount
	health_bar.value = health
	if health <= 0:
		died.emit()
		queue_free()
