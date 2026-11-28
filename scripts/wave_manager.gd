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
## Puntos fijos opcionales (se siguen usando como respaldo y como un punto más de variedad).
@export var spawn_points: Array[Marker2D] = []
## Zona jugable donde pueden aparecer enemigos (coordenadas globales, borde interior de las paredes).
@export var arena_rect: Rect2 = Rect2(-1789, -778, 3862, 2172)
## Distancia mínima (px) al jugador: nunca aparece nadie más cerca que esto.
@export var min_spawn_distance: float = 650.0
## Distancia máxima (px) al jugador para que el enemigo aparezca "cerca de la acción".
@export var max_spawn_distance: float = 1500.0
## Separación mínima (px) con las paredes.
@export var wall_margin: float = 90.0
## Segundos que se muestra el aviso (círculo rojo) antes de que salga el enemigo.
@export var spawn_warning_time: float = 0.7
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
## Segundos que tardan en aparecer todos los enemigos de la oleada actual (lo usa el bono de rapidez del puntaje).
var current_fast_time: float = 0.0
var _reported_wave: int = 0  # última oleada anunciada con wave_completed
var _spawning: bool = false
var _starting_wave: bool = false
var _completed: bool = false
## Para detectar enemigos atascados: {enemigo: {"pos": última posición, "still": segundos quieto}}.
var _track: Dictionary = {}
var _check_timer: float = 0.0
## Apariciones con aviso en curso: la oleada no termina mientras haya alguna pendiente.
var _pending: int = 0
## Sectores (de 8, alrededor del jugador) usados hace poco; se evita repetirlos para variar.
var _recent_sectors: Array[int] = []
var _flank_sector: int = -1
const SECTORS: int = 8
const SPAWN_TRIES: int = 24
## Duración (s) de la animación de entrada del enemigo.
const SPAWN_INTRO_TIME: float = 0.35
const PROBE_RADIUS: float = 45.0
## Capa de física de las paredes (Paredes usa la capa 1).
const WALL_MASK: int = 1


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
	var enemy_count: int = 0
	for key in wave:
		if key != "interval":
			enemy_count += wave[key]
	current_fast_time = enemy_count * wave.get("interval", spawn_interval) + spawn_warning_time
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
	if scene == null:
		push_warning("WaveManager: falta una escena de enemigo")
		return
	var pos: Vector2 = _find_spawn_position()
	_pending += 1
	_spawn_with_warning(scene, type, pos)


## Muestra un aviso en el suelo y, al terminar, hace aparecer al enemigo. Si el jugador se
## movió y quedó demasiado cerca, se busca otro lugar en el último momento.
func _spawn_with_warning(scene: PackedScene, type: String, pos: Vector2) -> void:
	var marker := SpawnWarning.new()
	marker.duration = spawn_warning_time
	add_child(marker)
	marker.global_position = pos
	await get_tree().create_timer(spawn_warning_time, false).timeout
	if not is_inside_tree():
		return
	marker.queue_free()
	_pending -= 1
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and pos.distance_to(player.global_position) < min_spawn_distance * 0.8:
		pos = _find_spawn_position()
	var enemy: Node = scene.instantiate()
	add_child(enemy)
	enemy.global_position = pos
	_enemies[enemy] = type
	enemy.died.connect(_on_enemy_died.bind(enemy))
	# Todos los enemigos de la oleada salen sabiendo dónde está el jugador.
	if player is Player:
		enemy.player = player
	_play_spawn_intro(enemy as Node2D, pos)
	_check_wave_finished()


## Animación de entrada: destello + el enemigo crece desde pequeño y se hace visible.
## Durante ese instante no se mueve ni ataca, para que no sea tosco ni injusto.
func _play_spawn_intro(enemy: Node2D, pos: Vector2) -> void:
	if enemy == null:
		return
	var burst := SpawnBurst.new()
	add_child(burst)
	burst.global_position = pos
	var target_scale: Vector2 = enemy.scale
	enemy.scale = target_scale * 0.2
	enemy.modulate.a = 0.0
	enemy.set_physics_process(false)
	var tween := enemy.create_tween().set_parallel(true)
	tween.tween_property(enemy, "scale", target_scale, SPAWN_INTRO_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "modulate:a", 1.0, SPAWN_INTRO_TIME * 0.8)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(enemy):
			enemy.set_physics_process(true))


## Elige un punto de aparición: lejos del jugador, dentro de la arena, sin tocar paredes y
## en un sector distinto a los últimos usados. Cada oleada usa un patrón distinto.
func _find_spawn_position() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return arena_rect.get_center()
	var origin: Vector2 = player.global_position
	var inner: Rect2 = arena_rect.grow(-wall_margin)

	var sector: int = _choose_sector()
	for attempt in SPAWN_TRIES:
		# los primeros intentos respetan el sector; luego se abre a cualquier dirección
		var s: int = sector if attempt < SPAWN_TRIES / 2 else randi() % SECTORS
		var angle: float = (float(s) + randf()) * TAU / SECTORS
		var dist: float = randf_range(min_spawn_distance, max_spawn_distance)
		var candidate: Vector2 = origin + Vector2.RIGHT.rotated(angle) * dist
		if _is_valid_spawn(candidate, origin, inner):
			_remember_sector(s)
			return candidate

	# Respaldo 1: punto al azar de la arena que cumpla las reglas.
	for i in 60:
		var c := Vector2(randf_range(inner.position.x, inner.end.x), randf_range(inner.position.y, inner.end.y))
		if _is_valid_spawn(c, origin, inner):
			return c
	# Respaldo 2: el punto fijo (o esquina) más lejano al jugador.
	var best: Vector2 = Vector2(inner.position.x, inner.position.y)
	var best_d: float = -1.0
	var options: Array[Vector2] = [inner.position, Vector2(inner.end.x, inner.position.y),
		Vector2(inner.position.x, inner.end.y), inner.end]
	for point in spawn_points:
		if point != null:
			options.append(point.global_position)
	for o in options:
		var d: float = o.distance_to(origin)
		if d > best_d:
			best_d = d
			best = o
	return best


func _is_valid_spawn(pos: Vector2, origin: Vector2, inner: Rect2) -> bool:
	if not inner.has_point(pos):
		return false
	if pos.distance_to(origin) < min_spawn_distance:
		return false
	return _is_free(pos)


## True si no hay paredes en un círculo alrededor del punto.
func _is_free(pos: Vector2) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = PROBE_RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	query.collision_mask = WALL_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return get_viewport().world_2d.direct_space_state.intersect_shape(query, 1).is_empty()


## Patrón según la oleada: 1-2 aleatorio; pares = tenaza (lados opuestos); impares = rodeo
## (sectores rotando). Siempre evita los sectores usados hace poco.
func _choose_sector() -> int:
	var pick: int = randi() % SECTORS
	if _wave_number % 2 == 0 and _wave_number > 0:
		# Tenaza: alterna un sector y el opuesto.
		if _flank_sector < 0 or _recent_sectors.size() % 2 == 0:
			_flank_sector = randi() % SECTORS
			return _flank_sector
		return (_flank_sector + SECTORS / 2) % SECTORS
	for i in 10:
		if not _recent_sectors.has(pick):
			break
		pick = randi() % SECTORS
	if _wave_number >= 3:
		var last: int = _recent_sectors.back() if not _recent_sectors.is_empty() else pick
		pick = (last + 3 + randi() % 3) % SECTORS  # salta lejos del último: rodea al jugador
	return pick


func _remember_sector(s: int) -> void:
	_recent_sectors.append(s)
	while _recent_sectors.size() > 3:
		_recent_sectors.pop_front()


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
	if _enemies.is_empty() and not _spawning and _pending == 0:
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
	if player == null:
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
				body.global_position = _find_spawn_position()
				info["pos"] = body.global_position
				info["still"] = 0.0
		else:
			info["still"] = 0.0  # cerca del jugador: está atacando o disparando, no atascado
		_track[enemy] = info


## Aviso visual: círculo rojo que late en el suelo antes de que aparezca un enemigo.
class SpawnWarning extends Node2D:
	var duration: float = 0.7
	var _t: float = 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(_t / maxf(duration, 0.01), 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_t * 18.0)
		var r: float = lerpf(46.0, 24.0, k)
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.1, 0.1, 0.15 + 0.25 * pulse))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(1.0, 0.3, 0.2, 0.9), 3.0)
		draw_line(Vector2(-10, -10), Vector2(10, 10), Color(1, 0.8, 0.6, 0.9), 3.0)
		draw_line(Vector2(10, -10), Vector2(-10, 10), Color(1, 0.8, 0.6, 0.9), 3.0)


## Destello que se expande al aparecer el enemigo y se borra solo.
class SpawnBurst extends Node2D:
	var _t: float = 0.0
	const LIFE: float = 0.4

	func _process(delta: float) -> void:
		_t += delta
		if _t >= LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(_t / LIFE, 0.0, 1.0)
		var r: float = lerpf(20.0, 85.0, k)
		var a: float = 1.0 - k
		draw_circle(Vector2.ZERO, r * 0.7, Color(1.0, 0.5, 0.3, 0.35 * a))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(1.0, 0.85, 0.6, a), 4.0)
