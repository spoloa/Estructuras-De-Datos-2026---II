class_name Player
extends CharacterBody2D
## Jugador: movimiento, vida, inventario de armas (DynamicArray), objetos usables y disparo hacia el mouse.

## Se emite cada vez que cambia la vida.
signal health_changed(current: int, maximum: int)
## Se emite al equipar o recoger un arma (slot = posición actual, total = armas en el inventario).
signal weapon_changed(weapon: WeaponData, slot: int, total: int)
## Se emite al recoger un objeto usable (ej. corazón).
signal consumable_added(data: ConsumableData)
## Se emite cuando se usa un objeto usable con éxito.
signal consumable_used(data: ConsumableData)
## Se emite al cambiar el objeto seleccionado (tecla switch_item).
signal consumable_selected(data: ConsumableData)
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
## Objetos usables que lleva el jugador (ej. corazón con cooldown).
var consumables: Array[ConsumableData] = []
## Posición del objeto seleccionado dentro de consumables.
var _selected_item: int = 0

var _slot: int = 0          # posición del arma equipada dentro del inventario
var _cooldown: float = 0.0  # segundos que faltan para poder volver a disparar
## Segundos que le faltan a cada objeto usable para poder usarse otra vez.
var _item_cooldowns: Dictionary = {}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	for w in starting_weapons:
		inventory.add(w)
	equip_weapon(0)


func _physics_process(delta: float) -> void:
	_move()
	_cooldown = maxf(0.0, _cooldown - delta)
	_update_item_cooldowns(delta)
	if Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_shoot()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_weapon"):
		equip_weapon((_slot + 1) % maxi(1, inventory.size()))
	elif event.is_action_pressed("switch_item"):
		select_next_consumable()
	elif event.is_action_pressed("use_item"):
		use_selected_consumable()


## Recupera vida sin pasar del máximo. Lo usarán ítems como el corazón.
func heal(amount: int) -> void:
	if health <= 0:
		return # Un jugador muerto no se cura

	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)

## Agrega un arma al inventario (por ejemplo, al recogerla del suelo).
func add_weapon(new_weapon: WeaponData) -> void:
	inventory.add(new_weapon)
	weapon_changed.emit(weapon, _slot, inventory.size())


## Agrega un objeto usable al inventario (por ejemplo, al recogerlo del suelo).
func add_consumable(data: ConsumableData) -> void:
	consumables.append(data)
	_item_cooldowns[data] = 0.0
	if consumables.size() == 1:
		_selected_item = 0
		consumable_selected.emit(data)
	consumable_added.emit(data)


## Cambia al siguiente objeto usable del inventario.
func select_next_consumable() -> void:
	if consumables.size() < 2:
		return
	_selected_item = (_selected_item + 1) % consumables.size()
	consumable_selected.emit(consumables[_selected_item])


## Objeto usable seleccionado (null si no hay ninguno).
func get_selected_consumable() -> ConsumableData:
	if consumables.is_empty():
		return null
	return consumables[clampi(_selected_item, 0, consumables.size() - 1)]


## Usa el objeto seleccionado. Devuelve true si se usó.
func use_selected_consumable() -> bool:
	var data := get_selected_consumable()
	return data != null and use_consumable(data)


## Intenta usar un objeto. Devuelve true si se usó.
## Su cooldown es propio: no afecta al cooldown de disparo de las armas.
func use_consumable(data: ConsumableData) -> bool:
	if health <= 0 or not consumables.has(data):
		return false
	if get_item_cooldown_left(data) > 0.0:
		return false  # todavía en cooldown
	match data.effect:
		ConsumableData.Effect.HEAL:
			if health >= max_health:
				return false  # vida llena: no gasta el cooldown
			heal(data.heal_amount)
		ConsumableData.Effect.BOMB:
			if not _throw_bomb(data):
				return false
	_item_cooldowns[data] = data.cooldown
	consumable_used.emit(data)
	return true


## Segundos restantes de cooldown de un objeto (útil para el HUD).
func get_item_cooldown_left(data: ConsumableData) -> float:
	return _item_cooldowns.get(data, 0.0)


func _update_item_cooldowns(delta: float) -> void:
	for data in _item_cooldowns.keys():
		_item_cooldowns[data] = maxf(0.0, _item_cooldowns[data] - delta)


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
	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if sprite == null:
		return
	var anim := "walk" if direction != Vector2.ZERO else "idle"
	if sprite.animation != anim:
		sprite.play(anim)
	# Mira hacia donde apunta el mouse, que es donde dispara
	sprite.flip_h = get_global_mouse_position().x < global_position.x

## Lanza la bomba hacia el mouse (limitada por max_range). Devuelve true si se lanzó.
func _throw_bomb(data: ConsumableData) -> bool:
	if data.bomb_scene == null:
		push_warning("Player: el objeto '%s' es bomba pero no tiene bomb_scene" % data.display_name)
		return false
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	var target: Vector2 = global_position + to_mouse.limit_length(data.max_range)
	var bomb: Bomb = data.bomb_scene.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = global_position
	bomb.setup(target, data.throw_speed, data.damage, data.blast_radius, self)
	return true


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
		bullet.setup(base_dir.rotated(angle), weapon.bullet_speed, weapon.damage, weapon.bullet_lifetime, self)
