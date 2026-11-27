extends Node2D
## Puente de señales de la escena Main.

@onready var wave_manager: WaveManager = $WaveManager
@onready var timeline: EventTimeline = $EventTimeline

func _ready() -> void:
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	timeline.loot_multiplier_changed.connect(_on_loot_multiplier_changed)
	timeline.event_started.connect(_on_event_started)
	timeline.event_ended.connect(_on_event_ended)

func _on_wave_started(number: int) -> void:
	timeline.start_wave(_events_for_wave(number))

func _on_wave_completed(_number: int) -> void:
	timeline.stop()
	ItemDrop.reset_chances()

func _on_loot_multiplier_changed(mult: float) -> void:
	ItemDrop.set_chance_multiplier(mult)

func _on_event_started(id: String, data: Dictionary) -> void:
	print("[Main] Evento iniciado: %s (%s)" % [id, data.get("type", "")])

func _on_event_ended(id: String, data: Dictionary) -> void:
	print("[Main] Evento terminado: %s (%s)" % [id, data.get("type", "")])
	if data.get("type", "") == "loot_hour":
		ItemDrop.set_chance_multiplier(1.0)

func _events_for_wave(number: int) -> Array:
	match number:
		1:
			return [
				{"id": "f1", "start_sec": 2.0, "end_sec": 6.0, "effect_type": "frenzy",
				 "params": {"speed_mult": 1.6}},
				{"id": "l1", "start_sec": 5.0, "end_sec": 9.0, "effect_type": "loot_hour",
				 "params": {"chance_mult": 2.0}},
				{"id": "d1", "start_sec": 7.0, "end_sec": 10.0, "effect_type": "danger_zone",
				 "params": {"radius": 120.0, "dps": 2.0}},
			]
		2:
			return [
				{"id": "l2", "start_sec": 1.0, "end_sec": 5.0, "effect_type": "loot_hour",
				 "params": {"chance_mult": 2.0}},
				{"id": "f2", "start_sec": 6.0, "end_sec": 10.0, "effect_type": "frenzy",
				 "params": {"speed_mult": 1.8}},
			]
		_:
			return [
				{"id": "d3", "start_sec": 3.0, "end_sec": 8.0, "effect_type": "danger_zone",
				 "params": {"radius": 160.0, "dps": 3.0}},
			]
