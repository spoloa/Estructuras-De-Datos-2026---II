class_name GameFlow
extends Node
## Controla cómo empieza y termina la partida:
##   - Al empezar            -> reinicia el puntaje (ScoreManager.start_run) y la XP/mejoras (UpgradeManager.reset)
##   - Mientras se juega     -> le pasa al puntaje los enemigos derrotados y las oleadas completadas
##   - Si el jugador muere   -> guarda la partida en el ranking y muestra "GAME OVER"
##   - Si se completan las oleadas -> guarda la partida en el ranking y muestra "¡VICTORIA!"

## Nodo Player (lee la señal died).
@export var player: Player
## Nodo WaveManager (lee las señales de oleadas y enemigos).
@export var wave_manager: WaveManager
## Segundos de espera antes de mostrar la pantalla final (para ver la muerte/el último enemigo).
@export var end_delay: float = 1.2

var _finished: bool = false


func _ready() -> void:
	if player == null or wave_manager == null:
		push_warning("GameFlow: falta asignar Player o WaveManager en el Inspector")
		return
	ScoreManager.start_run()
	UpgradeManager.reset()  # sin XP ni mejoras al empezar
	wave_manager.enemy_killed.connect(ScoreManager.add_kill)
	wave_manager.wave_completed.connect(ScoreManager.add_wave_bonus)
	player.died.connect(_on_player_died)
	wave_manager.all_waves_completed.connect(_on_victory)


func _on_player_died() -> void:
	_finish("GAME OVER", false)


func _on_victory() -> void:
	_finish("¡VICTORIA!", true)


## Guarda la partida y muestra la pantalla final una sola vez, aunque lleguen dos señales seguidas.
func _finish(title: String, victory: bool) -> void:
	if _finished:
		return
	_finished = true
	# Se guarda de inmediato (antes de la espera): si cierran el juego en ese momento no se pierde.
	var result: Dictionary = ScoreManager.submit(victory)
	ScreenManager.pause_enabled = false  # ya no tiene sentido pausar
	await get_tree().create_timer(end_delay).timeout
	if not is_inside_tree():
		return
	ScreenManager.push_screen(EndScreen.new(title, result))
