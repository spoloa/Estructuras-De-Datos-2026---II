extends Label
## HUD del juego: muestra la vida, el arma equipada y la oleada actual.
##
## Reemplaza al HUD de prueba. Sigue siendo un Label (el mismo nodo de Main.tscn),
## solo que ahora también escucha al WaveManager.
##
## En el Inspector hay que asignar:
##   - player:        el nodo Player
##   - wave_manager:  el nodo WaveManager

## Nodo Player (de él se lee la vida y el arma).
@export var player: Player
## Nodo WaveManager (de él se lee la oleada actual).
@export var wave_manager: WaveManager
## Tamaño de la letra.
@export var font_size: int = 24

var _health_text: String = ""
var _weapon_text: String = ""
var _wave_text: String = ""


func _ready() -> void:
	# Letra más grande y con borde negro para que se lea sobre cualquier fondo.
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)

	if player == null:
		push_warning("HUD: falta asignar el Player en el Inspector")
	else:
		player.health_changed.connect(_on_health_changed)
		player.weapon_changed.connect(_on_weapon_changed)
		# El Player ya se inicializó antes que el HUD, así que leemos su estado actual.
		_on_health_changed(player.health, player.max_health)
		_on_weapon_changed(player.weapon, 0, player.inventory.size())

	if wave_manager == null:
		push_warning("HUD: falta asignar el WaveManager en el Inspector")
	else:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)
		_wave_text = "Oleada: preparándose..."
	_refresh()


func _on_health_changed(current: int, maximum: int) -> void:
	_health_text = "Vida: %d / %d" % [current, maximum]
	_refresh()


func _on_weapon_changed(weapon: WeaponData, slot: int, total: int) -> void:
	if weapon == null:
		_weapon_text = "Sin arma"
	else:
		_weapon_text = "Arma: %s (%d/%d)  [Q] cambiar" % [weapon.weapon_name, slot + 1, total]
	_refresh()


## Cuando empieza una oleada, el WaveManager ya sacó esa oleada de su cola (Queue),
## así que las que quedan en la cola + la actual = total de oleadas.
func _on_wave_started(number: int) -> void:
	var total: int = number + wave_manager.waves.size()
	_wave_text = "Oleada: %d / %d" % [number, total]
	_refresh()


func _on_all_waves_completed() -> void:
	_wave_text = "¡Oleadas completadas!"
	_refresh()


func _refresh() -> void:
	var lines: Array[String] = [_health_text, _weapon_text]
	if _wave_text != "":
		lines.append(_wave_text)
	text = "\n".join(lines)
