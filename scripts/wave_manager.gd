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
var _alive: int = 0
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
	if _starting_wave or _completed:
		return
	if waves.is_empty():
		_completed = true
		all_waves_completed.emit()
		return
	_starting_wave = true
	await get_tree().create_timer(time_between_waves).timeout
	_starting_wave = false

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
	enemy.died.connect(_on_enemy_died)
	_alive += 1


func _on_enemy_died() -> void:
	_alive -= 1
	_check_wave_finished()


func _check_wave_finished() -> void:
	if _alive <= 0 and not _spawning:
		_start_next_wave()
