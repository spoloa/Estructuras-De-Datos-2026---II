extends Node
## Puntaje de la partida y ranking de todas las partidas jugadas.
##
## El ranking es un árbol AVL (AVLTree.gd) cuya clave es el puntaje. Se guarda en disco
## (user://ranking.save) y se vuelve a cargar al abrir el juego.
##
## Se registra como Autoload con el nombre "ScoreManager" (Proyecto > Configuración
## del proyecto > Globales), por eso este script NO declara class_name.
##
## Flujo de una partida (lo dirige GameFlow.gd):
##   start_run()                 al empezar la partida (reinicia puntaje y tiempo)
##   add_kill(tipo)              cada vez que muere un enemigo
##   add_wave_bonus(n)           cada vez que se completa una oleada
##   submit(victoria)            al terminar: guarda la partida en el ranking
##                               y devuelve el puntaje y la posición obtenida

## Se emite cada vez que cambia el puntaje de la partida en curso.
signal score_changed(new_score: int)

## Archivo donde se guarda el ranking.
const SAVE_PATH: String = "user://ranking.save"

## Puntos por enemigo según su tipo (los mismos nombres que usa WaveManager).
const POINTS_PER_KILL: Dictionary = {"chaser": 100, "shooter": 150}
## Puntos por un enemigo de tipo desconocido.
const DEFAULT_KILL_POINTS: int = 50
## Puntos por cada oleada completada.
const WAVE_BONUS: int = 200
## Puntos extra por ganar la partida (completar todas las oleadas).
const VICTORY_BONUS: int = 1000

## Ranking de todas las partidas: AVL ordenado por puntaje.
var ranking: AVLTree = AVLTree.new()
## Archivo que se usa para guardar y cargar (se puede cambiar en las pruebas).
var save_path: String = SAVE_PATH

## Puntaje de la partida en curso.
var score: int = 0
## Segundos jugados en la partida en curso (no cuenta el tiempo en pausa).
var run_time: float = 0.0
## Oleadas completadas en la partida en curso.
var waves_completed: int = 0

var _running: bool = false
var _submitted: bool = false
var _last_result: Dictionary = {}


func _ready() -> void:
	load_from(save_path)


func _process(delta: float) -> void:
	# El árbol de escenas en pausa no ejecuta _process, así que la pausa no suma tiempo.
	if _running:
		run_time += delta


## Empieza una partida nueva: puntaje, tiempo y oleadas en cero.
func start_run() -> void:
	score = 0
	run_time = 0.0
	waves_completed = 0
	_submitted = false
	_last_result = {}
	_running = true
	score_changed.emit(score)


## Suma los puntos de un enemigo derrotado.
func add_kill(enemy_type: String) -> void:
	add_points(POINTS_PER_KILL.get(enemy_type, DEFAULT_KILL_POINTS))


## Suma el bono de una oleada completada.
func add_wave_bonus(_wave_number: int) -> void:
	if not _running:
		return
	waves_completed += 1
	add_points(WAVE_BONUS)


## Suma puntos al puntaje de la partida en curso.
func add_points(amount: int) -> void:
	if not _running:
		return
	score += amount
	score_changed.emit(score)


## Termina la partida: la guarda en el ranking y devuelve el resultado:
##   {"score", "id", "rank" (1 = la mejor), "total" (partidas en el ranking),
##    "waves", "time", "victory", "new_record"}
## Solo guarda una vez por partida: si se llama de nuevo devuelve el mismo resultado.
func submit(victory: bool) -> Dictionary:
	if _submitted:
		return _last_result
	_submitted = true
	_running = false
	if victory:
		score += VICTORY_BONUS
		score_changed.emit(score)

	var value: Dictionary = {
		"waves": waves_completed,
		"time": run_time,
		"victory": victory,
		"date": Time.get_datetime_string_from_system().replace("T", " ").substr(0, 16),
	}
	var id: int = ranking.insert(score, value)
	var position: int = ranking.rank(score, id)
	save_to(save_path)

	_last_result = {
		"score": score,
		"id": id,
		"rank": position,
		"total": ranking.size(),
		"waves": waves_completed,
		"time": run_time,
		"victory": victory,
		"new_record": position == 1 and ranking.size() > 1,
	}
	return _last_result


## Resultado de la última partida enviada (vacío si todavía no hay ninguna).
func get_last_result() -> Dictionary:
	return _last_result


## Tiempo en formato mm:ss.
func format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


# ---------------------------------------------------------------------------
# Guardado en disco
# ---------------------------------------------------------------------------

## Guarda todo el ranking recorriéndolo en preorden. Devuelve false si no se pudo escribir.
func save_to(path: String) -> bool:
	var entries: Array = []
	for entry in ranking.to_array_preorder():
		var saved: Dictionary = (entry["value"] as Dictionary).duplicate()
		saved["score"] = entry["key"]
		saved["id"] = entry["id"]
		entries.append(saved)

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("ScoreManager: no se pudo guardar el ranking (%s)" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify({"version": 1, "entries": entries}, "\t"))
	file.close()
	return true


## Reconstruye el ranking leyendo el archivo: cada registro se vuelve a insertar en el
## árbol con su id original, así los empates conservan su orden de llegada.
## Si el archivo no existe (primera vez) el ranking queda vacío y devuelve true.
## Si está dañado, el ranking queda vacío, avisa en la consola y devuelve false.
func load_from(path: String) -> bool:
	ranking.clear()
	if not FileAccess.file_exists(path):
		return true

	var json: JSON = JSON.new()  # a diferencia de JSON.parse_string, no imprime errores del motor
	var data: Variant = null
	if json.parse(FileAccess.get_file_as_string(path)) == OK:
		data = json.data
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("entries")) != TYPE_ARRAY:
		push_warning("ScoreManager: el archivo del ranking está dañado, se empieza con uno vacío")
		return false

	for item in data["entries"]:
		if typeof(item) != TYPE_DICTIONARY or not item.has("score") or not item.has("id"):
			continue  # registro incompleto: se ignora
		var value: Dictionary = {
			"waves": int(item.get("waves", 0)),
			"time": float(item.get("time", 0.0)),
			"victory": bool(item.get("victory", false)),
			"date": str(item.get("date", "")),
		}
		ranking.insert(int(item["score"]), value, int(item["id"]))
	return true
