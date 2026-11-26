class_name ItemDrop
extends RefCounted
## Ayudante estático: decide si un enemigo suelta un ítem al morir.

## Probabilidad de soltar un arma nueva (0.0 a 1.0). Se elige al azar entre DROP_WEAPONS.
const WEAPON_CHANCE: float = 0.15
## Probabilidad de soltar una bomba (0.0 a 1.0).
const BOMB_CHANCE: float = 0.20
## Probabilidad de soltar un dash (0.0 a 1.0).
const DASH_CHANCE: float = 0.15
## Probabilidad de soltar un corazón (0.0 a 1.s0).
const HEART_CHANCE: float = 0.25
## Armas que se pueden encontrar en el suelo (no se sueltan las que el jugador ya tiene ni las que ya están en el suelo).
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


## Tira los dados y, si toca, deja un ítem en la posición de source.
static func try_drop(source: Node2D) -> void:
	var roll: float = randf()
	var item := ItemPickup.new()
	if roll < WEAPON_CHANCE:
		var weapon: WeaponData = _pick_weapon(source)
		if weapon == null:
			item.free()  # ya tiene todas las armas: no hay nada que soltar
			return
		item.kind = ItemPickup.Kind.WEAPON
		item.weapon = weapon
	elif roll < WEAPON_CHANCE + BOMB_CHANCE:
		if _stack_full(source, DROP_BOMB):
			item.free()  # ya lleva el máximo de bombas: no se suelta otra
			return
		item.kind = ItemPickup.Kind.CONSUMABLE
		item.consumable = DROP_BOMB
	elif roll < WEAPON_CHANCE + BOMB_CHANCE + DASH_CHANCE:
		var player := _get_player(source)
		if (player != null and player.ability == DROP_DASH) or ItemPickup.is_on_floor(ItemPickup.Kind.ABILITY, DROP_DASH):
			item.free()  # ya tiene el dash, o ya hay uno en el suelo: no se suelta otro
			return
		item.kind = ItemPickup.Kind.ABILITY
		item.ability = DROP_DASH
	elif roll < WEAPON_CHANCE + BOMB_CHANCE + DASH_CHANCE + HEART_CHANCE:
		if _stack_full(source, DROP_CONSUMABLE):
			item.free()  # ya lleva el máximo de corazones: no se suelta otro
			return
		item.kind = ItemPickup.Kind.CONSUMABLE
		item.consumable = DROP_CONSUMABLE
	else:
		item.free()  # no toca ítem
		return

	# Se hace en diferido porque el enemigo muere dentro de una colisión de la bala,
	# y Godot no permite agregar áreas de colisión mientras procesa la física.
	var position: Vector2 = source.global_position
	ItemPickup.register(item)
	source.get_tree().current_scene.add_child.call_deferred(item)
	item.set_deferred("global_position", position)


## Elige al azar un arma de DROP_WEAPONS que el jugador todavía no tenga (null si ya las tiene todas).
static func _pick_weapon(source: Node2D) -> WeaponData:
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
static func _stack_full(source: Node2D, data: ConsumableData) -> bool:
	var player := _get_player(source)
	return player != null and player.get_consumable_count(data) >= Player.MAX_CONSUMABLE_STACK


## El jugador de la partida (null si no se encuentra).
static func _get_player(source: Node2D) -> Player:
	return source.get_tree().get_first_node_in_group("player") as Player
