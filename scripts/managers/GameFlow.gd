class_name GameFlow
extends Node
## Controla cómo termina la partida:
##   - Si el jugador muere        -> pantalla "GAME OVER"
##   - Si se completan las oleadas -> pantalla "¡VICTORIA!"
##
## Es un nodo suelto dentro de Main.tscn. En el Inspector hay que asignar
## el Player y el WaveManager.

## Nodo Player (se escucha su señal died).
@export var player: Player
## Nodo WaveManager (se escucha su señal all_waves_completed).
@export var wave_manager: WaveManager
## Segundos de espera antes de mostrar la pantalla final (para ver la muerte/el último enemigo).
@export var end_delay: float = 1.2

var _finished: bool = false


func _ready() -> void:
	if player == null or wave_manager == null:
		push_warning("GameFlow: falta asignar Player o WaveManager en el Inspector")
		return
	player.died.connect(_on_player_died)
	wave_manager.all_waves_completed.connect(_on_victory)


func _on_player_died() -> void:
	_finish("GAME OVER")


func _on_victory() -> void:
	_finish("¡VICTORIA!")


## Muestra la pantalla final una sola vez, aunque lleguen dos señales seguidas.
func _finish(title: String) -> void:
	if _finished:
		return
	_finished = true
	ScreenManager.pause_enabled = false  # ya no tiene sentido pausar
	await get_tree().create_timer(end_delay).timeout
	if not is_inside_tree():
		return
	ScreenManager.push_screen(EndScreen.new(title))
