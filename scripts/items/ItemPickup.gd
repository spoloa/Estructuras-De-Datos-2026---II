class_name ItemPickup
extends Area2D
## Ítem recolectable en el suelo. Se crea completo desde código (no necesita escena).
## Tipos:
##   CONSUMABLE -> objeto usable con cooldown (ej. corazón): va al inventario de consumibles.
##   WEAPON     -> arma: se agrega al inventario de armas (Player.add_weapon).
##   ABILITY    -> habilidad (ej. dash): se usa con Shift izquierdo (Player.add_ability).

enum Kind { CONSUMABLE, WEAPON, ABILITY }

## Tipo de ítem.
@export var kind: Kind = Kind.CONSUMABLE
## Objeto que entrega (solo para CONSUMABLE).
@export var consumable: ConsumableData
## Arma que entrega (solo para WEAPON).
@export var weapon: WeaponData
## Habilidad que entrega (solo para ABILITY).
@export var ability: AbilityData

## Ítems que hay en el suelo (o a punto de ponerse). Sirve para que no haya dos armas ni dos
## dash iguales regados: ItemDrop no suelta uno si ya hay otro, y al recoger uno se borran los demás.
static var _on_floor: Array = []

## Textura del arma en el suelo (ajusta la ruta a tu PNG).
const WEAPON_TEXTURE: Texture2D = preload("res://assets/items/escopeta.png")
## Radio de colisión del ítem en píxeles.
const RADIUS: float = 45.0
## Tamaño en el suelo de las armas (lado más grande, en píxeles).
const WEAPON_SIZE: float = 150.0
## Tamaño en el suelo de los objetos (corazón, bomba). Su imagen está recortada a su
## contenido, así que se ve más grande que el arma con el mismo número: por eso es menor.
## Si todavía se ven grandes, baja este número; si se ven chicos, súbelo.
const CONSUMABLE_SIZE: float = 65.0
## Multiplicador individual por arma en el suelo (1.0 = tamaño base de WEAPON_SIZE).
## Cambia la clave según la propiedad de nombre que tenga tu WeaponData (ej. "weapon_name", "name" o "id").
const WEAPON_SIZE_MULTIPLIERS: Dictionary = {
	"bate": 0.5,
	"bazuca": 0.9,
	"escopeta": 1.0,
}


## Anota un ítem recién creado en la lista del suelo (lo llama ItemDrop).
static func register(item: ItemPickup) -> void:
	item._registered_frame = Engine.get_process_frames()
	_on_floor.append(item)


## true si ya hay en el suelo (o a punto de ponerse) un arma / habilidad igual a resource.
static func is_on_floor(item_kind: Kind, resource: Resource) -> bool:
	_on_floor = _on_floor.filter(func(i: Variant) -> bool: return is_instance_valid(i) and i.is_active())
	for other in _on_floor:
		if other.kind == item_kind and other.get_payload() == resource:
			return true
	return false


## Frame en que se creó (para no contar ítems que nunca llegaron a la escena).
var _registered_frame: int = -100


## El recurso que entrega según su tipo.
func get_payload() -> Resource:
	match kind:
		Kind.WEAPON:
			return weapon
		Kind.ABILITY:
			return ability
	return consumable


## true si está en la escena, o se creó hace un instante y está por entrar.
func is_active() -> bool:
	return is_inside_tree() or Engine.get_process_frames() - _registered_frame <= 2


func _exit_tree() -> void:
	_on_floor.erase(self)


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	var sprite := Sprite2D.new()
	match kind:
		Kind.CONSUMABLE:
			if consumable != null:
				sprite.texture = consumable.get_icon()
		Kind.ABILITY:
			if ability != null:
				sprite.texture = ability.get_icon()
		Kind.WEAPON:
			# Cada arma puede traer su propia imagen (WeaponData.icon).
			if weapon != null and weapon.icon != null:
				sprite.texture = weapon.icon
			else:
				sprite.texture = WEAPON_TEXTURE
	if sprite.texture != null:
		var target_size: float = WEAPON_SIZE if kind == Kind.WEAPON else CONSUMABLE_SIZE
		var tex_size: Vector2 = sprite.texture.get_size()
		var factor: float = target_size / maxf(tex_size.x, tex_size.y)
		if kind == Kind.WEAPON and weapon != null:
			factor *= _get_weapon_multiplier(weapon)
		sprite.scale = Vector2(factor, factor)
	add_child(sprite)

	body_entered.connect(_on_body_entered)


func _get_weapon_multiplier(w: WeaponData) -> float:
	for prop in ["weapon_name", "id", "name", "resource_name"]:
		var val: Variant = w.get(prop)
		if val != null and String(val) != "":
			var key := String(val).strip_edges().to_lower()
			if WEAPON_SIZE_MULTIPLIERS.has(key):
				return float(WEAPON_SIZE_MULTIPLIERS[key])
	return 1.0


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return  # solo el jugador recoge ítems

	match kind:
		Kind.CONSUMABLE:
			# Los objetos se apilan (3 corazones, 5 bombas). Si ya llevas el máximo se queda en el suelo.
			if consumable == null or not player.add_consumable(consumable):
				return
		Kind.WEAPON:
			if weapon == null or player.inventory.contains(weapon):
				return  # no repetir armas (usa DynamicArray.contains)
			player.add_weapon(weapon)
			_remove_duplicates()
		Kind.ABILITY:
			if ability == null or player.ability == ability:
				return  # no repetir la misma habilidad
			player.add_ability(ability)
			_remove_duplicates()
	queue_free()


## Al recoger un arma o habilidad, borra del suelo las demás iguales para que no queden regadas.
func _remove_duplicates() -> void:
	for other in _on_floor:
		if other != self and is_instance_valid(other) and other.kind == kind and other.get_payload() == get_payload():
			other.queue_free()
