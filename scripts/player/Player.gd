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
## Se emite cuando cambia la cantidad de unidades de un objeto (al recoger o al usar uno).
signal consumable_count_changed(data: ConsumableData, count: int)
## Se emite al cambiar el objeto seleccionado (tecla switch_item).
signal consumable_selected(data: ConsumableData)
## Se emite al conseguir una habilidad (por ejemplo, al recoger el dash del suelo).
signal ability_changed(data: AbilityData)
## Se emite cuando se usa la habilidad con éxito.
signal ability_used(data: AbilityData)
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
## Objetos con los que empieza el jugador (opcional).
@export var starting_consumables: Array[ConsumableData] = []
## Habilidad con la que empieza el jugador (opcional, por ejemplo Dash.tres; sirve para probar).
@export var starting_ability: AbilityData

var health: int
var weapon: WeaponData  # arma equipada actualmente
## Inventario de armas: arreglo dinámico propio (ver DynamicArray.gd).
var inventory: DynamicArray = DynamicArray.new()
## Objetos usables que lleva el jugador (ej. corazón con cooldown).
var consumables: Array[ConsumableData] = []
## Máximo de unidades que se pueden llevar de cada objeto (corazón, bomba).
const MAX_CONSUMABLE_STACK: int = 9
## Unidades que tienes de cada objeto: {ConsumableData: cantidad}. Un objeto se queda en
## `consumables` aunque llegue a 0 (así sigues teniéndolo "descubierto" y sus mejoras cuentan).
var _consumable_counts: Dictionary = {}
## Posición del objeto seleccionado dentro de consumables.
var _selected_item: int = 0

var _slot: int = 0          # posición del arma equipada dentro del inventario
var _cooldown: float = 0.0  # segundos que faltan para poder volver a disparar
## Segundos que le faltan a cada objeto usable para poder usarse otra vez.
var _item_cooldowns: Dictionary = {}

## Habilidad que tiene el jugador (null = ninguna). Se usa con la acción "dash" (Shift izquierdo).
var ability: AbilityData = null
## Segundos que le faltan a la habilidad para poder usarse otra vez.
var _ability_cooldown: float = 0.0

## Nombre de la acción de teclado de la habilidad.
const ABILITY_ACTION: String = "dash"
## Opacidad del jugador mientras hace el dash.
const DASH_ALPHA: float = 0.45
## Segundos que le faltan al dash actual (0 = no está haciendo dash).
var _dash_time_left: float = 0.0
var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_invulnerable: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")  # para que los drops sepan qué armas y habilidades ya tienes
	_ensure_ability_action()
	health = max_health
	for w in starting_weapons:
		inventory.add(w)
	equip_weapon(0)
	for c in starting_consumables:
		add_consumable(c)
	if starting_ability != null:
		add_ability(starting_ability)


func _physics_process(delta: float) -> void:
	if _dash_time_left > 0.0:
		_dash_step(delta)  # durante el dash no se controla el movimiento
	else:
		_move()
	_cooldown = maxf(0.0, _cooldown - delta)
	_update_item_cooldowns(delta)
	_ability_cooldown = maxf(0.0, _ability_cooldown - delta)
	if Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_shoot()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_weapon"):
		equip_weapon((_slot + 1) % maxi(1, inventory.size()))
	elif event.is_action_pressed("switch_item"):
		select_next_consumable()
	elif event.is_action_pressed("use_item"):
		use_selected_consumable()
	elif event.is_action_pressed(ABILITY_ACTION):
		use_ability()


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


## Agrega unidades de un objeto usable (por ejemplo, al recogerlo del suelo). Las unidades
## se apilan: 3 corazones son una sola entrada con cantidad 3.
## Devuelve false si no se pudo (objeto nulo o ya llevas el máximo), para que el ítem siga en el suelo.
func add_consumable(data: ConsumableData, amount: int = 1) -> bool:
	if data == null or amount <= 0:
		return false
	var current: int = get_consumable_count(data)
	if current >= MAX_CONSUMABLE_STACK:
		return false
	if not consumables.has(data):
		consumables.append(data)
		if not _item_cooldowns.has(data):
			_item_cooldowns[data] = 0.0  # si ya lo tuvo antes, conserva su recarga (no se salta el cooldown)
		if consumables.size() == 1:
			_selected_item = 0
			consumable_selected.emit(data)
	_consumable_counts[data] = mini(MAX_CONSUMABLE_STACK, current + amount)
	consumable_added.emit(data)
	consumable_count_changed.emit(data, _consumable_counts[data])
	return true


## Cuántas unidades tienes de un objeto (0 si no lo tienes).
func get_consumable_count(data: ConsumableData) -> int:
	return _consumable_counts.get(data, 0)


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
	if health <= 0 or not consumables.has(data) or get_consumable_count(data) <= 0:
		return false  # sin unidades no se puede usar
	if get_item_cooldown_left(data) > 0.0:
		return false  # todavía en cooldown
	match data.effect:
		ConsumableData.Effect.HEAL:
			if health >= max_health:
				return false  # vida llena: no gasta el cooldown
			heal(roundi(UpgradeManager.stat(data.display_name, "heal_amount", data.heal_amount)))
		ConsumableData.Effect.BOMB:
			if not _throw_bomb(data):
				return false
	_consumable_counts[data] = get_consumable_count(data) - 1  # gasta una unidad
	_item_cooldowns[data] = get_item_cooldown(data)
	consumable_count_changed.emit(data, _consumable_counts[data])
	consumable_used.emit(data)
	return true


## Cooldown total del objeto con las mejoras compradas (mínimo 1 segundo).
func get_item_cooldown(data: ConsumableData) -> float:
	return maxf(1.0, UpgradeManager.stat(data.display_name, "cooldown", data.cooldown))


## Segundos restantes de cooldown de un objeto (útil para el HUD).
func get_item_cooldown_left(data: ConsumableData) -> float:
	return _item_cooldowns.get(data, 0.0)


## Consigue una habilidad (la reemplaza si ya tenías otra distinta).
func add_ability(data: AbilityData) -> void:
	if data == null or ability == data:
		return
	ability = data
	_ability_cooldown = 0.0
	ability_changed.emit(data)


## Usa la habilidad (Shift izquierdo). Devuelve true si se usó.
## Su cooldown es propio: no afecta a las armas ni a los objetos.
func use_ability() -> bool:
	if ability == null or health <= 0 or _ability_cooldown > 0.0:
		return false
	match ability.kind:
		AbilityData.Kind.DASH:
			if not _start_dash(ability):
				return false
	_ability_cooldown = get_ability_cooldown()
	ability_used.emit(ability)
	return true


## Cooldown total de la habilidad con las mejoras compradas (mínimo medio segundo).
func get_ability_cooldown() -> float:
	if ability == null:
		return 0.0
	return maxf(0.5, UpgradeManager.stat(ability.display_name, "cooldown", ability.cooldown))


## Segundos restantes de cooldown de la habilidad (útil para el HUD).
func get_ability_cooldown_left() -> float:
	return _ability_cooldown


## Crea la acción de teclado de la habilidad (Shift izquierdo) si no existe en el Input Map.
## Así funciona sin tocar project.godot; si ya la creaste a mano, se respeta la tuya.
func _ensure_ability_action() -> void:
	if InputMap.has_action(ABILITY_ACTION):
		return
	InputMap.add_action(ABILITY_ACTION)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SHIFT
	key.location = KEY_LOCATION_LEFT  # solo el Shift izquierdo
	InputMap.action_add_event(ABILITY_ACTION, key)


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
	if _dash_invulnerable and _dash_time_left > 0.0:
		return  # el dash esquiva el daño mientras dura
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
	var bomb_damage: int = roundi(UpgradeManager.stat(data.display_name, "damage", data.damage))
	var bomb_radius: float = UpgradeManager.stat(data.display_name, "blast_radius", data.blast_radius)
	bomb.setup(target, data.throw_speed, bomb_damage, bomb_radius, self)
	return true


## Impulso rápido (dash) en la dirección en que te mueves; si estás quieto, hacia el mouse.
func _start_dash(data: AbilityData) -> bool:
	if _dash_time_left > 0.0:
		return false  # ya está en un dash
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = (get_global_mouse_position() - global_position).normalized()
	if dir == Vector2.ZERO:
		return false
	var duration: float = maxf(data.dash_duration, 0.01)
	var distance: float = UpgradeManager.stat(data.display_name, "dash_distance", data.dash_distance)
	_dash_velocity = dir.normalized() * (distance / duration)
	_dash_time_left = duration
	_dash_invulnerable = data.dash_invulnerable
	if sprite != null:
		sprite.modulate.a = DASH_ALPHA
	return true


## Avanza el dash un frame. Al terminar, el jugador vuelve a ser controlable.
func _dash_step(delta: float) -> void:
	_dash_time_left -= delta
	velocity = _dash_velocity
	move_and_slide()
	if _dash_time_left <= 0.0:
		_dash_time_left = 0.0
		_dash_invulnerable = false
		velocity = Vector2.ZERO
		if sprite != null:
			sprite.modulate.a = 1.0


## Ataca según los datos del arma equipada (disparo o golpe cuerpo a cuerpo).
func _shoot() -> void:
	if weapon == null:
		return
	_cooldown = 1.0 / maxf(0.05, UpgradeManager.stat(weapon.weapon_name, "fire_rate", weapon.fire_rate))
	if weapon.attack_type == WeaponData.AttackType.MELEE:
		_melee_attack()
	else:
		_fire_projectiles()


## Dispara balas (pistola, escopeta) o un cohete (bazuca).
func _fire_projectiles() -> void:
	if weapon.rocket_scene == null and bullet_scene == null:
		return
	var base_dir := (get_global_mouse_position() - global_position).normalized()
	# Estadísticas con las mejoras compradas (ver UpgradeManager.stat).
	var key: String = weapon.weapon_name
	var pellets: int = maxi(1, roundi(UpgradeManager.stat(key, "bullets_per_shot", weapon.bullets_per_shot)))
	var damage: int = roundi(UpgradeManager.stat(key, "damage", weapon.damage))
	var blast: float = UpgradeManager.stat(key, "blast_radius", weapon.blast_radius)
	for i in pellets:
		var angle := deg_to_rad(randf_range(-weapon.spread_degrees, weapon.spread_degrees))
		var dir := base_dir.rotated(angle)
		if weapon.rocket_scene != null:
			var rocket: Rocket = weapon.rocket_scene.instantiate()
			get_tree().current_scene.add_child(rocket)
			rocket.global_position = global_position
			rocket.setup(dir, weapon.bullet_speed, damage, weapon.bullet_lifetime, self, blast)
		else:
			var bullet: Bullet = bullet_scene.instantiate()
			get_tree().current_scene.add_child(bullet)
			bullet.global_position = global_position
			bullet.setup(dir, weapon.bullet_speed, damage, weapon.bullet_lifetime, self)


## Golpe cuerpo a cuerpo: daña a todo lo que esté dentro del alcance y del arco hacia el mouse.
func _melee_attack() -> void:
	var aim := (get_global_mouse_position() - global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var melee_range: float = UpgradeManager.stat(weapon.weapon_name, "melee_range", weapon.melee_range)
	var melee_damage: int = roundi(UpgradeManager.stat(weapon.weapon_name, "damage", weapon.damage))

	# Efecto visual del golpe.
	var swing := MeleeSwing.new()
	add_child(swing)
	swing.play(aim, melee_range, weapon.melee_arc_degrees)

	# Todo lo que toque el círculo de alcance...
	var shape := CircleShape2D.new()
	shape.radius = melee_range
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 64)

	# ...y que además esté dentro del arco, recibe el daño (una sola vez por cuerpo).
	var half_arc: float = deg_to_rad(weapon.melee_arc_degrees) / 2.0
	var already_hit: Dictionary = {}
	for hit in hits:
		var target: Object = hit.collider
		if target == self or target is Player or already_hit.has(target):
			continue
		already_hit[target] = true
		if not target.has_method("take_damage"):
			continue
		var to_target: Vector2 = (target as Node2D).global_position - global_position
		if to_target == Vector2.ZERO or absf(aim.angle_to(to_target)) <= half_arc:
			target.take_damage(melee_damage)
