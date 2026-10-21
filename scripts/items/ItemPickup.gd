class_name ItemPickup
extends Area2D
## Ítem recolectable en el suelo. Se crea completo desde código (no necesita escena).
## Tipos:
##   HEART  -> círculo rojo con una cruz: cura al jugador (Player.heal).
##   WEAPON -> círculo amarillo: agrega un arma al inventario (Player.add_weapon).

enum Kind { HEART, WEAPON }

## Tipo de ítem.
@export var kind: Kind = Kind.HEART
## Vida que cura (solo para HEART).
@export var heal_amount: int = 1
## Arma que entrega (solo para WEAPON).
@export var weapon: WeaponData

## Radio del ítem en píxeles (dibujo y colisión).
const RADIUS: float = 18.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


## Dibujo provisional del ítem.
func _draw() -> void:
	match kind:
		Kind.HEART:
			draw_circle(Vector2.ZERO, RADIUS, Color(0.9, 0.15, 0.2))
			draw_rect(Rect2(-9, -3, 18, 6), Color.WHITE)
			draw_rect(Rect2(-3, -9, 6, 18), Color.WHITE)
		Kind.WEAPON:
			draw_circle(Vector2.ZERO, RADIUS, Color(0.95, 0.75, 0.1))
			draw_rect(Rect2(-10, -4, 20, 8), Color(0.2, 0.2, 0.2))


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return  # solo el jugador recoge ítems

	match kind:
		Kind.HEART:
			if player.health >= player.max_health:
				return  # vida llena: el corazón se queda en el suelo
			player.heal(heal_amount)
		Kind.WEAPON:
			if weapon == null or player.inventory.contains(weapon):
				return  # no repetir armas (usa DynamicArray.contains)
			player.add_weapon(weapon)
	queue_free()
