class_name Player
extends CharacterBody2D
## Jugador: movimiento, vida, inventario de armas (DynamicArray) y disparo hacia el mouse.

## Se emite cada vez que cambia la vida.
signal health_changed(current: int, maximum: int)
## Se emite al equipar o recoger un arma (slot = posición actual, total = armas en el inventario).
signal weapon_changed(weapon: WeaponData, slot: int, total: int)
## Se emite cuando la vida llega a 0.
signal died

## Velocidad de movimiento en píxeles por segundo.
@export var speed: float = 300.0
## Vida máxima del jugador.
@export var max_health: int = 5
## Escena del proyectil (Bullet.tscn).
@export var bullet_scene: PackedScene
## Armas con las que empieza el jugador (se cargan al inventario en _ready).
@export var starting_weapons: Array[WeaponData] = []

var health: int
var weapon: WeaponData  # arma equipada actualmente
## Inventario de armas: arreglo dinámico propio (ver DynamicArray.gd).
var inventory: DynamicArray = DynamicArray.new()

var _slot: int = 0          # posición del arma equipada dentro del inventario
var _cooldown: float = 0.0  # segundos que faltan para poder volver a disparar


func _ready() -> void:
	health = max_health
	for w in starting_weapons:
		inventory.add(w)
	equip_weapon(0)


func _physics_process(delta: float) -> void:
	_move()
	_cooldown = maxf(0.0, _cooldown - delta)
	if Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_shoot()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_weapon"):
		equip_weapon((_slot + 1) % maxi(1, inventory.size()))
	elif event.is_action_pressed("ui_accept"):
		take_damage(1)  # TEMPORAL: prueba de vida con Espacio/Enter, borrar cuando haya enemigos


## Agrega un arma al inventario (por ejemplo, al recogerla del suelo).
func add_weapon(new_weapon: WeaponData) -> void:
	inventory.add(new_weapon)
	weapon_changed.emit(weapon, _slot, inventory.size())


## Equipa el arma que está en la posición slot del inventario.
func equip_weapon(slot: int) -> void:
	if inventory.is_empty():
		return
	_slot = slot
	weapon = inventory.get_at(slot)
	weapon_changed.emit(weapon, _slot, inventory.size())


## Resta vida. Si llega a 0, el jugador muere.
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		set_physics_process(false)


func _move() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()


## Dispara según los datos del arma equipada.
func _shoot() -> void:
	if weapon == null or bullet_scene == null:
		return
	_cooldown = 1.0 / weapon.fire_rate
	var base_dir := (get_global_mouse_position() - global_position).normalized()
	for i in weapon.bullets_per_shot:
		var angle := deg_to_rad(randf_range(-weapon.spread_degrees, weapon.spread_degrees))
		var bullet: Bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		bullet.setup(base_dir.rotated(angle), weapon.bullet_speed, weapon.damage, weapon.bullet_lifetime)
