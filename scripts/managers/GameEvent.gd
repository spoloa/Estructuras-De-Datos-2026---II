class_name GameEvent
extends Resource
## Definición de un evento temporal de una oleada.

@export var id: String = ""
@export var nombre: String = ""
@export var start_sec: float = 0.0
@export var end_sec: float = 5.0
## "frenzy" | "loot_hour" | "danger_zone"
@export var effect_type: String = ""
## Parámetros libres: multiplicadores, radios, dps...
@export var params: Dictionary = {}

func to_data() -> Dictionary:
	return { "type": effect_type, "nombre": nombre, "params": params }
