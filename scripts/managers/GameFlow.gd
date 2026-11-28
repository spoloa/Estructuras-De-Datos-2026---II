class_name GameFlow
extends Node
## Controla cómo empieza y termina la partida y conecta los sistemas entre sí:
##   - Al empezar            -> reinicia puntaje y efectos, y pone la música del juego
##   - Mientras se juega     -> le pasa al puntaje los enemigos derrotados, las oleadas completadas
##                              y el daño recibido; avisa cuando sube el nivel del combo
##   - Si el jugador muere   -> guarda la partida en el ranking y muestra "GAME OVER"
##   - Si se completan las oleadas -> guarda la partida en el ranking y muestra "¡VICTORIA!"

## Nodo Player (lee las señales died y damaged).
@export var player: Player
## Nodo WaveManager (lee las señales de oleadas y enemigos).
@export var wave_manager: WaveManager
## Segundos de espera antes de mostrar la pantalla final (para ver la muerte/el último enemigo).
@export var end_delay: float = 1.2

const COLOR_COMBO: Color = Color(1.0, 0.55, 0.15)
## Segundos que dura la animación de muerte antes de mostrar "GAME OVER" (en la victoria se usa end_delay).
const DEATH_DELAY: float = 2.2

var _finished: bool = false
var _last_multiplier: float = 1.0


func _ready() -> void:
	if player == null or wave_manager == null:
		push_warning("GameFlow: falta asignar Player o WaveManager en el Inspector")
		return
	GameFeel.reset()
	ScoreManager.start_run()
	AudioManager.play_music("game")
	wave_manager.enemy_killed.connect(ScoreManager.add_kill)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(ScoreManager.add_wave_bonus)
	ScoreManager.combo_changed.connect(_on_combo_changed)
	player.damaged.connect(func(_amount: int) -> void: ScoreManager.on_player_hit())
	player.died.connect(_on_player_died)
	wave_manager.all_waves_completed.connect(_on_victory)


## Al empezar la oleada el puntaje arranca su cronómetro de bonos.
## current_fast_time lo calcula WaveManager (segundos que tardan en salir todos los enemigos).
func _on_wave_started(number: int) -> void:
	var fast_time: Variant = wave_manager.get("current_fast_time")
	ScoreManager.start_wave(number, float(fast_time) if fast_time != null else 0.0)


## Al subir de nivel de combo suena una nota más aguda y aparece un aviso sobre el jugador.
## (Es el único texto flotante del puntaje: los puntos de cada enemigo no se muestran.)
func _on_combo_changed(kills: int, multiplier: float) -> void:
	if multiplier > _last_multiplier and is_instance_valid(player):
		AudioManager.play("combo", 0.0, 0.0, multiplier / 1.5)
		ComboPopup.spawn(get_tree().current_scene, player.global_position + Vector2(0, -50), "¡COMBO x%s!" % ScoreManager.multiplier_text(multiplier), COLOR_COMBO, 34)
	_last_multiplier = multiplier if kills > 0 else 1.0


func _on_player_died() -> void:
	if _finished:
		return
	PlayerDeathEffect.play(player)
	# El mundo se congela mientras el personaje cae: los enemigos dejan de moverse y atacar.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	_finish("GAME OVER", false)


func _on_victory() -> void:
	_finish("¡VICTORIA!", true)


## Guarda la partida y muestra la pantalla final una sola vez, aunque lleguen dos señales seguidas.
func _finish(title: String, victory: bool) -> void:
	if _finished:
		return
	_finished = true
	# Se guarda de inmediato (antes de la espera): si cierran el juego en ese momento no se pierde.
	var result: Dictionary = ScoreManager.submit(victory, PlayerProfile.nickname)
	ScreenManager.pause_enabled = false  # ya no tiene sentido pausar
	AudioManager.stop_music(1.0)
	if victory:
		AudioManager.play("victory")
	else:
		# La melodía de derrota entra después del efecto de muerte, para que no se pisen los sonidos.
		get_tree().create_timer(1.4, true, false, true).timeout.connect(func() -> void: AudioManager.play("defeat", -3.0))
	await get_tree().create_timer(end_delay if victory else DEATH_DELAY, true, false, true).timeout
	if not is_inside_tree():
		return
	ScreenManager.push_screen(EndScreen.new(title, result))
