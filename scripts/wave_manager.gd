class_name WaveManager
extends Node
## Oleadas con Queue (orden de las oleadas) y PriorityQueue (orden de aparición dentro de cada oleada).

signal wave_started(number: int)
signal all_waves_completed

@export var shooter_scene: PackedScene
@export var chaser_scene: PackedScene
@export var spawn_points: Array[Marker2D] = []
@export var time_between_waves: float = 3.0
@export var spawn_interval: float = 1.0

## Prioridad de aparición por tipo: mayor número = sale antes.
const PRIORITY := {"chaser": 2, "shooter": 1}

var waves: Queue = Queue.new()
## Enemigos vivos de la oleada. Es un diccionario (no un contador) para que un enemigo
## cuente una sola vez aunque su señal 'died' se emita dos veces.
var _enemies: Dictionary = {}
var _wave_number: int = 0
var _spawning: bool = false
var _starting_wave: bool = false
var _completed: bool = false


func _ready() -> void:
	# Cada oleada: cuántos enemigos de cada tipo. Edita estos números a gusto.
	waves.enqueue({"chaser": 2, "shooter": 1})
	waves.enqueue({"chaser": 3, "shooter": 3})
	waves.enqueue({"chaser": 4, "shooter": 5})
	_start_next_wave()


func _start_next_wave() -> void:
	if _starting_wave or _completed or not is_inside_tree():
		return  # si el WaveManager ya salió del árbol (cambio/reinicio de escena) no hace nada
	if waves.is_empty():
		_completed = true
		all_waves_completed.emit()
		return
	_starting_wave = true
	await get_tree().create_timer(time_between_waves).timeout
	_starting_wave = false
	if not is_inside_tree():
		return

	var wave: Dictionary = waves.dequeue()   # Queue: sale la primera oleada encolada
	_wave_number += 1
	wave_started.emit(_wave_number)

	# PriorityQueue: ordena los enemigos de esta oleada por prioridad
	var orders := PriorityQueue.new()
	for type in wave:
		for i in wave[type]:
			orders.enqueue(type, PRIORITY[type])

	_spawning = true
	while not orders.is_empty():
		_spawn_enemy(orders.dequeue())   # primero el de mayor prioridad
		await get_tree().create_timer(spawn_interval).timeout
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
	_enemies[enemy] = true
	enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_enemy_died(enemy: Node) -> void:
	if not _enemies.has(enemy):
		return  # ya estaba descontado (señal repetida): se ignora
	_enemies.erase(enemy)
	_check_wave_finished()


func _check_wave_finished() -> void:
	if _enemies.is_empty() and not _spawning:
		_start_next_wave()
