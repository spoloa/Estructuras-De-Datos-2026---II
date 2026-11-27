extends Node
## Autoload "ItemDrop". Decide si un enemigo suelta un ítem al morir.
## OJO: Al ser Autoload, NO lleva "class_name ItemDrop" para no chocar con el nombre global.

# --- Probabilidades base (no cambian) ---
const _BASE_WEAPON: float = 0.15
const _BASE_BOMB: float = 0.20
const _BASE_DASH: float = 0.15
const _BASE_HEART: float = 0.25

# --- Probabilidades actuales (pueden cambiar por eventos) ---
var WEAPON_CHANCE: float = _BASE_WEAPON
var BOMB_CHANCE: float = _BASE_BOMB
var DASH_CHANCE: float = _BASE_DASH
var HEART_CHANCE: float = _BASE_HEART

## Armas que se pueden encontrar en el suelo
const DROP_WEAPONS := [
	preload("res://resources/weapons/Escopeta.tres"),
	preload("res://resources/weapons/Bazuca.tres"),
	preload("res://resources/weapons/Bate.tres"),
]
## Bomba que se puede encontrar en el suelo.
const DROP_BOMB: ConsumableData = preload("res://resources/consumables/BombaObjeto.tres")
## Habilidad (dash) que se puede encontrar en el suelo.
const DROP_DASH: AbilityData = preload("res://resources/abilities/Dash.tres")
## Objeto usable que se puede encontrar en el suelo (corazón con cooldown).
const DROP_CONSUMABLE: ConsumableData = preload("res://resources/consumables/Corazon.tres")


## Multiplica las probabilidades base (ej. 2.0 para duplicar en "Hora del botín").
func set_chance_multiplier(mult: float) -> void:
	WEAPON_CHANCE = _BASE_WEAPON * mult
	BOMB_CHANCE = _BASE_BOMB * mult
	DASH_CHANCE = _BASE_DASH * mult
	HEART_CHANCE = _BASE_HEART * mult

## Restaura las probabilidades a la normalidad.
func reset_chances() -> void:
	set_chance_multiplier(1.0)


## Tira los dados y, si toca, deja un ítem en la posición de source.
func try_drop(source: Node2D) -> void:
	var roll: float = randf()
	var item := ItemPickup.new()
	
	# Calculamos los límites acumulados basados en las variables actuales
	var limit_weapon: float = WEAPON_CHANCE
	var limit_bomb: float = limit_weapon + BOMB_CHANCE
	var limit_dash: float = limit_bomb + DASH_CHANCE
	var limit_heart: float = limit_dash + HEART_CHANCE

	if roll < limit_weapon:
		var weapon: WeaponData = _pick_weapon(source)
		if weapon == null:
			item.free()
			return
		item.kind = ItemPickup.Kind.WEAPON
		item.weapon = weapon
	elif roll < limit_bomb:
		if _stack_full(source, DROP_BOMB):
			item.free()
			return
		item.kind = ItemPickup.Kind.CONSUMABLE
		item.consumable = DROP_BOMB
	elif roll < limit_dash:
		var player := _get_player(source)
		if (player != null and player.ability == DROP_DASH) or ItemPickup.is_on_floor(ItemPickup.Kind.ABILITY, DROP_DASH):
			item.free()
			return
		item.kind = ItemPickup.Kind.ABILITY
		item.ability = DROP_DASH
	elif roll < limit_heart:
		if _stack_full(source, DROP_CONSUMABLE):
			item.free()
			return
		item.kind = ItemPickup.Kind.CONSUMABLE
		item.consumable = DROP_CONSUMABLE
	else:
		item.free()
		return

	var position: Vector2 = source.global_position
	ItemPickup.register(item)
	source.get_tree().current_scene.add_child.call_deferred(item)
	item.set_deferred("global_position", position)


## Elige al azar un arma de DROP_WEAPONS que el jugador todavía no tenga.
func _pick_weapon(source: Node2D) -> WeaponData:
	var player := _get_player(source)
	var candidates: Array[WeaponData] = []
	for w in DROP_WEAPONS:
		var already_has: bool = player != null and player.inventory.contains(w)
		if not already_has and not ItemPickup.is_on_floor(ItemPickup.Kind.WEAPON, w):
			candidates.append(w)
	if candidates.is_empty():
		return null
	return candidates.pick_random()


## true si el jugador ya lleva el máximo de unidades de ese objeto.
func _stack_full(source: Node2D, data: ConsumableData) -> bool:
	var player := _get_player(source)
	return player != null and player.get_consumable_count(data) >= Player.MAX_CONSUMABLE_STACK


## El jugador de la partida (null si no se encuentra).
func _get_player(source: Node2D) -> Player:
	return source.get_tree().get_first_node_in_group("player") as Player
