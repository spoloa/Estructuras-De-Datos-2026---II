class_name WaveManager
extends Node
## Oleadas con Queue (orden de las oleadas) y PriorityQueue (orden de aparición dentro de cada oleada).

signal wave_started(number: int)
## Se emite cuando se derrotan todos los enemigos de una oleada (una vez por oleada).
signal wave_completed(number: int)
## Se emite cuando muere un enemigo; type es "chaser" o "shooter". Lo usa el puntaje.
signal enemy_killed(type: String)
signal all_waves_completed

@export var shooter_scene: PackedScene
@export var chaser_scene: PackedScene
@export var spawn_points: Array[Marker2D] = []
@export var time_between_waves: float = 3.5
@export var spawn_interval: float = 1.5

## Prioridad de aparición por tipo: mayor número = sale antes.
const PRIORITY := {"chaser": 2, "shooter": 1}

## Anti-atascos: cada STUCK_CHECK_INTERVAL segundos se revisa si algún enemigo lleva
## STUCK_SECONDS casi sin moverse estando lejos del jugador (atorado en una pared, por ejemplo).
## Si es así, se le cambia de lugar a un punto de aparición para que la oleada pueda terminar.
const STUCK_CHECK_INTERVAL: float = 1.0
const STUCK_SECONDS: float = 6.0
## Lo que se mueve menos que esto (px) en cada revisión cuenta como "quieto".
const STUCK_MIN_MOVE: float = 12.0
## Solo se considera atascado si está más lejos que esto del jugador (los tiradores se detienen a disparar).
const STUCK_MIN_DISTANCE: float = 300.0

var waves: Queue = Queue.new()
## Enemigos vivos de la oleada. Es un diccionario (no un contador) para que un enemigo
## cuente una sola vez aunque su señal 'died' se emita dos veces. Guarda el tipo de cada enemigo.
var _enemies: Dictionary = {}
var _wave_number: int = 0
var _reported_wave: int = 0  # última oleada anunciada con wave_completed
var _spawning: bool = false
var _starting_wave: bool = false
var _completed: bool = false
## Para detectar enemigos atascados: {enemigo: {"pos": última posición, "still": segundos quieto}}.
var _track: Dictionary = {}
var _check_timer: float = 0.0


func _ready() -> void:
	# Cada oleada: cuántos enemigos de cada tipo. Edita estos números a gusto.
	# "interval" (opcional) = segundos entre cada aparición en esa oleada; si no está se usa spawn_interval.
	waves.enqueue({"chaser": 4, "shooter": 2})                      # 1: 6 enemigos
	waves.enqueue({"chaser": 6, "shooter": 4})                      # 2: 10
	waves.enqueue({"chaser": 8, "shooter": 6})                      # 3: 14
	waves.enqueue({"chaser": 10, "shooter": 8})                     # 4: 18
	waves.enqueue({"chaser": 10, "shooter": 10})                     # 5: 18, 
	waves.enqueue({"chaser": 14, "shooter": 12, "interval": 1.5})   # 6: 26, respiro antes del final
	waves.enqueue({"chaser": 18, "shooter": 14, "interval": 1.0})   # 7: 32, la más difícil: salen casi en avalancha
	_start_next_wave()


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < STUCK_CHECK_INTERVAL:
		return
	_check_timer = 0.0
	if _purge_freed():
		_check_wave_finished()
	_relocate_stuck_enemies()


func _start_next_wave() -> void:
	if _starting_wave or _completed or not is_inside_tree():
		return  # si el WaveManager ya salió del árbol (cambio/reinicio de escena) no hace nada
	if waves.is_empty():
		_completed = true
		all_waves_completed.emit()
		return
	_starting_wave = true
	await get_tree().create_timer(time_between_waves, false).timeout
	_starting_wave = false
	if not is_inside_tree():
		return

	var wave: Dictionary = waves.dequeue()   # Queue: sale la primera oleada encolada
	_wave_number += 1
	wave_started.emit(_wave_number)

	# PriorityQueue: ordena los enemigos de esta oleada por prioridad
	var orders := PriorityQueue.new()
	for type in wave:
		if type == "interval":
			continue  # no es un tipo de enemigo
		for i in wave[type]:
			orders.enqueue(type, PRIORITY[type])

	var interval: float = wave.get("interval", spawn_interval)
	_spawning = true
	while not orders.is_empty():
		_spawn_enemy(orders.dequeue())   # primero el de mayor prioridad
		# El timer se pausa con el juego (process_always = false): no salen enemigos con la pantalla de mejoras abierta.
		await get_tree().create_timer(interval, false).timeout
		if not is_inside_tree():
			return
	_spawning = false
	_check_wave_finished()


func _spawn_enemy(type: String) -> void:
	var scene: PackedScene = chaser_scene if type == "chaser" else shooter_scene
	if scene == null or spawn_points.is_empty():
		push_warning("WaveManager: falta una escena o spawn_points")
		return
	var point: Marker2D = spawn_points.pick_random()
	if point == null:
		push_warning("WaveManager: hay un Spawn Point vacío en el Inspector")
		return
	var enemy: Node = scene.instantiate()
	add_child(enemy)
	enemy.global_position = point.global_position
	_enemies[enemy] = type
	enemy.died.connect(_on_enemy_died.bind(enemy))
	# Todos los enemigos de la oleada salen sabiendo dónde está el jugador. Antes un perseguidor
	# se quedaba quieto hasta que el jugador entraba en su rango de detección, y si nadie se
	# acercaba la oleada no terminaba nunca (parecía que "no salen más bichos").
	var target: Player = get_tree().get_first_node_in_group("player") as Player
	if target != null:
		enemy.player = target


func _on_enemy_died(enemy: Node) -> void:
	if not _enemies.has(enemy):
		return  # ya estaba descontado (señal repetida): se ignora
	var type: String = _enemies[enemy]
	_enemies.erase(enemy)
	_track.erase(enemy)
	enemy_killed.emit(type)
	_check_wave_finished()


func _check_wave_finished() -> void:
	_purge_freed()
	if _enemies.is_empty() and not _spawning:
		if _reported_wave != _wave_number:  # se anuncia una sola vez por oleada
			_reported_wave = _wave_number
			wave_completed.emit(_wave_number)
		_start_next_wave()


## Quita de la cuenta a los enemigos que ya no existen (se borraron sin emitir 'died'); si no,
## la oleada esperaría para siempre a un enemigo fantasma. Devuelve true si quitó alguno.
func _purge_freed() -> bool:
	var removed: bool = false
	for enemy in _enemies.keys():
		if not is_instance_valid(enemy):
			_enemies.erase(enemy)
			_track.erase(enemy)
			removed = true
	return removed


## Cambia de lugar a los enemigos que llevan mucho tiempo quietos lejos del jugador (atascados).
func _relocate_stuck_enemies() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or spawn_points.is_empty():
		return
	for enemy in _enemies.keys():
		var body: Node2D = enemy as Node2D
		var info: Dictionary = _track.get(enemy, {"pos": body.global_position, "still": 0.0})
		if body.global_position.distance_to(info["pos"]) > STUCK_MIN_MOVE:
			info["pos"] = body.global_position
			info["still"] = 0.0
		elif body.global_position.distance_to(player.global_position) > STUCK_MIN_DISTANCE:
			info["still"] += STUCK_CHECK_INTERVAL
			if info["still"] >= STUCK_SECONDS:
				var point: Marker2D = spawn_points.pick_random()
				if point != null:
					body.global_position = point.global_position
				info["pos"] = body.global_position
				info["still"] = 0.0
		else:
			info["still"] = 0.0  # cerca del jugador: está atacando o disparando, no atascado
		_track[enemy] = info
