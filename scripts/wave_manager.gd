class_name WaveManager
extends Node
## Genera oleadas de enemigos usando una Queue (FIFO).

signal wave_started(number: int)
signal all_waves_completed

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker2D] = []
## Cantidad de enemigos de cada oleada, en orden.
@export var enemies_per_wave: Array[int] = [2, 3, 5]
@export var time_between_waves: float = 3.0
@export var spawn_interval: float = 0.5

var waves: Queue = Queue.new()
var _alive: int = 0
var _wave_number: int = 0
var _spawning: bool = false
var _starting_wave: bool = false

func _ready() -> void:
	for count in enemies_per_wave:
		waves.enqueue(count)   # encola cada oleada en orden
	_start_next_wave()


func _start_next_wave() -> void:
	if _starting_wave:
		return
	if waves.is_empty():
		all_waves_completed.emit()
		return
	_starting_wave = true
	await get_tree().create_timer(time_between_waves).timeout
	_starting_wave = false
	if waves.is_empty():
		return
	var count: int = waves.dequeue()
	_wave_number += 1
	wave_started.emit(_wave_number)
	_spawning = true
	for i in count:
		_spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout
	_spawning = false
	_check_wave_finished()


func _spawn_enemy() -> void:
	if enemy_scene == null or spawn_points.is_empty():
		push_warning("WaveManager: falta enemy_scene o spawn_points")
		return
	var enemy: Enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_points.pick_random().global_position
	enemy.died.connect(_on_enemy_died)
	_alive += 1


func _on_enemy_died() -> void:
	_alive -= 1
	_check_wave_finished()


func _check_wave_finished() -> void:
	# Solo pasa a la siguiente cuando ya no quedan vivos y terminó de generar
	if _alive <= 0 and not _spawning:
		_start_next_wave()
