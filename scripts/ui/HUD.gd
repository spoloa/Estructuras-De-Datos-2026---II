extends Label
## HUD mínimo de prueba: muestra vida y arma equipada.
## La Persona 3 puede reemplazarlo luego por el HUD definitivo.

## Arrastra aquí el nodo Player desde el Inspector.
@export var player: Player

var _health_text: String = ""
var _weapon_text: String = ""


func _ready() -> void:
	if player == null:
		push_warning("HUD: falta asignar el Player en el Inspector")
		return
	player.health_changed.connect(_on_health_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.died.connect(_on_died)
	# El Player ya se inicializó antes que el HUD, así que leemos su estado actual.
	_on_health_changed(player.health, player.max_health)
	_on_weapon_changed(player.weapon, 0, player.inventory.size())


func _on_health_changed(current: int, maximum: int) -> void:
	_health_text = "Vida: %d / %d" % [current, maximum]
	_refresh()


func _on_weapon_changed(weapon: WeaponData, slot: int, total: int) -> void:
	if weapon == null:
		_weapon_text = "Sin arma"
	else:
		_weapon_text = "Arma: %s (%d/%d)  [Q] cambiar" % [weapon.weapon_name, slot + 1, total]
	_refresh()


func _on_died() -> void:
	text = "GAME OVER"


func _refresh() -> void:
	text = _health_text + "\n" + _weapon_text
