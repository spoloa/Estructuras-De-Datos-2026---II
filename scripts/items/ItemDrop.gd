class_name ItemDrop
extends RefCounted
## Ayudante estático: decide si un enemigo suelta un ítem al morir.

## Probabilidad de soltar un arma nueva (0.0 a 1.0).
const WEAPON_CHANCE: float = 0.20
## Probabilidad de soltar una bomba (0.0 a 1.0).
const BOMB_CHANCE: float = 0.20
## Probabilidad de soltar un corazón (0.0 a 1.0).
const HEART_CHANCE: float = 0.25
## Arma que se puede encontrar en el suelo.
const DROP_WEAPON: WeaponData = preload("res://resources/weapons/Escopeta.tres")
## Bomba que se puede encontrar en el suelo.
const DROP_BOMB: WeaponData = preload("res://resources/weapons/Bomba.tres")
## Objeto usable que se puede encontrar en el suelo (corazón con cooldown).
const DROP_CONSUMABLE: ConsumableData = preload("res://resources/consumables/Corazon.tres")


## Tira los dados y, si toca, deja un ítem en la posición de source.
static func try_drop(source: Node2D) -> void:
	var roll: float = randf()
	var item := ItemPickup.new()
	if roll < WEAPON_CHANCE:
		item.kind = ItemPickup.Kind.WEAPON
		item.weapon = DROP_WEAPON
	elif roll < WEAPON_CHANCE + BOMB_CHANCE:
		item.kind = ItemPickup.Kind.WEAPON
		item.weapon = DROP_BOMB
	elif roll < WEAPON_CHANCE + BOMB_CHANCE + HEART_CHANCE:
		item.kind = ItemPickup.Kind.CONSUMABLE
		item.consumable = DROP_CONSUMABLE
	else:
		item.free()  # no toca ítem
		return

	# Se hace en diferido porque el enemigo muere dentro de una colisión de la bala,
	# y Godot no permite agregar áreas de colisión mientras procesa la física.
	var position: Vector2 = source.global_position
	source.get_tree().current_scene.add_child.call_deferred(item)
	item.set_deferred("global_position", position)
