class_name EventTimeline
extends Node
## Gestiona los eventos temporales usando un IntervalTree.

signal event_started(event_id: String, data: Dictionary)
signal event_ended(event_id: String, data: Dictionary)
signal loot_multiplier_changed(mult: float)

@export var tick_interval: float = 1.0
@export var max_simultaneous: int = 2
@export var allow_overlap: bool = true

var tree: IntervalTree = IntervalTree.new()
var _active: Dictionary = {}  # Solo guarda los datos (Dictionaries) de los eventos activos
var _event_nodes: Dictionary = {} # Diccionario SEPARADO para guardar los nodos visuales (zonas, etc.)
var _elapsed: float = 0.0
var _next_tick: float = 0.0
var _running: bool = false

func _ready() -> void:
	set_process(false)

func start_wave(events: Array) -> void:
	stop()
	_elapsed = 0.0
	_next_tick = tick_interval
	_running = true

	for ev in events:
		var start: float
		var end: float
		var id: String
		var data: Dictionary

		if ev is GameEvent:
			start = ev.start_sec
			end = ev.end_sec
			id = ev.id
			data = ev.to_data()
		else:
			start = float(ev.get("start_sec", 0.0))
			end = float(ev.get("end_sec", 5.0))
			id = String(ev.get("id", "ev_" + str(randi())))
			data = {
				"type": String(ev.get("effect_type", "")),
				"nombre": String(ev.get("nombre", id)),
				"params": ev.get("params", {})
			}

		var overlaps: Array[Dictionary] = tree.query_overlap(start, end)
		if overlaps.size() >= max_simultaneous:
			push_warning("EventTimeline: '%s' descartado (max simultáneos)" % id)
			continue
		if not allow_overlap and not overlaps.is_empty():
			push_warning("EventTimeline: '%s' descartado (solape)" % id)
			continue
		tree.insert(start, end, id, data)

	set_process(true)
	print("EventTimeline: %d eventos cargados" % tree.size)

func stop() -> void:
	if not _running:
		tree.clear()
		_active.clear()
		for node in _event_nodes.values():
			if is_instance_valid(node): node.queue_free()
		_event_nodes.clear()
		return
		
	for id in _active.keys():
		event_ended.emit(id, _active[id])
		_cleanup_node(id)
		
	_active.clear()
	tree.clear()
	_running = false
	set_process(false)

func get_active_ids() -> Array:
	return _active.keys()

func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	while _elapsed >= _next_tick:
		_update_active(_next_tick)
		_next_tick += tick_interval

func _update_active(t: float) -> void:
	var now: Array[Dictionary] = tree.query_point(t)
	var now_ids: Dictionary = {}
	for e in now:
		now_ids[e["id"]] = e["data"]

	# 1. Revisar eventos que TERMINAN
	for id in _active.keys():
		if not now_ids.has(id):
			event_ended.emit(id, _active[id])
			_cleanup_node(id)
			_active.erase(id)

	# 2. Revisar eventos que EMPIEZAN
	for id in now_ids.keys():
		if not _active.has(id):
			_active[id] = now_ids[id]
			_apply_effect(id, now_ids[id])
			event_started.emit(id, now_ids[id])

func _cleanup_node(id: String) -> void:
	# Limpia los nodos visuales asociados a este evento
	if _event_nodes.has(id):
		var node = _event_nodes[id]
		if is_instance_valid(node):
			node.queue_free()
		_event_nodes.erase(id)
		
	# También revisa si dejamos zonas de gas sueltas (terminan en _1, _2, _3)
	for key in _event_nodes.keys():
		if key.begins_with(id):
			var node = _event_nodes[key]
			if is_instance_valid(node): node.queue_free()
			_event_nodes.erase(key)

func _apply_effect(id: String, data: Dictionary) -> void:
	var effect: String = data.get("type", "")
	var params: Dictionary = data.get("params", {})
	
	match effect:
		"frenzy":
			print("[Evento] ¡Frenesí!")
			# get_tree().call_group("enemies", "set_speed_multiplier", params.get("speed_mult", 1.8))
			
		"loot_hour", "bomb_rain":
			var mult: float = params.get("chance_mult", params.get("bomb_mult", 2.0))
			loot_multiplier_changed.emit(mult)
			print("[Evento] Botín aumentado (x%.2f)" % mult)
			
		"danger_zone":
			_spawn_danger_zone(id, params, false)
			print("[Evento] Zona de peligro")
			
		"tear_gas":
			_spawn_danger_zone(id + "_1", params, true)
			_spawn_danger_zone(id + "_2", params, true)
			_spawn_danger_zone(id + "_3", params, true)
			print("[Evento] ¡Gases!")
			
		"curfew":
			var dark = CanvasModulate.new()
			dark.color = Color(0.3, 0.3, 0.4)
			get_tree().current_scene.add_child(dark)
			_event_nodes[id] = dark
			print("[Evento] Toque de queda")
			
		_:
			print("[Evento] '%s' sin efecto" % effect)

func _spawn_danger_zone(id: String, params: Dictionary, random_pos: bool) -> void:
	var scene: PackedScene = load("res://scenes/DangerZone.tscn")
	if scene == null:
		push_warning("Falta res://scenes/DangerZone.tscn")
		return
		
	var zone: Node2D = scene.instantiate()
	zone.setup(params.get("radius", 100.0), params.get("dps", 1.0))
	
	if random_pos:
		zone.position = Vector2(randf_range(-600, 600), randf_range(-300, 300))
	else:
		zone.position = Vector2.ZERO
		
	get_tree().current_scene.add_child(zone)
	# ¡OJO AQUÍ! Ahora se guarda en _event_nodes, NO en _active
	_event_nodes[id] = zone
