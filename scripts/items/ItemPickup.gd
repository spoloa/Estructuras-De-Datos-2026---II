class_name ItemPickup
extends Area2D
## Ítem recolectable en el suelo. Se crea completo desde código (no necesita escena).
## Tipos:
##   CONSUMABLE -> objeto usable con cooldown (ej. corazón): va al inventario de consumibles.
##   WEAPON     -> arma: se agrega al inventario de armas (Player.add_weapon).

enum Kind { CONSUMABLE, WEAPON }

## Tipo de ítem.
@export var kind: Kind = Kind.CONSUMABLE
## Objeto que entrega (solo para CONSUMABLE).
@export var consumable: ConsumableData
## Arma que entrega (solo para WEAPON).
@export var weapon: WeaponData

## Textura del arma en el suelo (ajusta la ruta a tu PNG).
const WEAPON_TEXTURE: Texture2D = preload("res://assets/items/escopeta.png")
## Radio de colisión del ítem en píxeles.
const RADIUS: float = 45.0
## Tamaño en el suelo de las armas (lado más grande, en píxeles).
const WEAPON_SIZE: float = 150.0
## Tamaño en el suelo de los objetos (corazón, bomba). Su imagen está recortada a su
## contenido, así que se ve más grande que el arma con el mismo número: por eso es menor.
## Si todavía se ven grandes, baja este número; si se ven chicos, súbelo.
const CONSUMABLE_SIZE: float = 60.0


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
		Kind.WEAPON:
			# Cada arma puede traer su propia imagen (WeaponData.icon).
			if weapon != null and weapon.icon != null:
				sprite.texture = weapon.icon
			else:
				sprite.texture = WEAPON_TEXTURE
	if sprite.texture != null:
		var target_size: float = CONSUMABLE_SIZE if kind == Kind.CONSUMABLE else WEAPON_SIZE
		var tex_size: Vector2 = sprite.texture.get_size()
		var factor: float = target_size / maxf(tex_size.x, tex_size.y)
		sprite.scale = Vector2(factor, factor)
	add_child(sprite)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return  # solo el jugador recoge ítems

	match kind:
		Kind.CONSUMABLE:
			if consumable == null or player.consumables.has(consumable):
				return  # no repetir objetos
			player.add_consumable(consumable)
		Kind.WEAPON:
			if weapon == null or player.inventory.contains(weapon):
				return  # no repetir armas (usa DynamicArray.contains)
			player.add_weapon(weapon)
	queue_free()
