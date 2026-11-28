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
##   start_run()                 al empezar la partida (reinicia puntaje, tiempo y combo)
##   start_wave(n, tiempo_rapido) al empezar cada oleada (para los bonos de tiempo y de "sin daño")
##   add_kill(tipo)              cada vez que muere un enemigo (aplica el combo)
##   on_player_hit()             cada vez que el jugador recibe daño (rompe el combo)
##   add_wave_bonus(n)           al completar una oleada (base + bono de rapidez + bono sin daño)
##   submit(victoria, nickname)  al terminar: guarda la partida en el ranking
##                               y devuelve el puntaje y la posición obtenida

## Se emite cada vez que cambia el puntaje de la partida en curso.
signal score_changed(new_score: int)
## Se emite cuando cambia el combo: kills seguidas y multiplicador actual (0 kills = combo roto).
signal combo_changed(kills: int, multiplier: float)
## Se emite al completar una oleada con el desglose de bonos: {"base", "time", "clean", "total"}.
signal wave_bonus_awarded(wave_number: int, bonus: Dictionary)

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

## Segundos sin matar a nadie antes de que se rompa el combo.
const COMBO_WINDOW: float = 4.0
## Multiplicadores del combo: [kills seguidas necesarias, multiplicador]. Se usa el último que se cumpla.
const COMBO_TIERS: Array = [[0, 1.0], [3, 1.5], [6, 2.0], [10, 3.0]]
## Bono máximo por terminar una oleada rápido (se gana si terminas justo cuando sale el último enemigo).
const TIME_BONUS_MAX: int = 300
## Segundos después del tiempo "rápido" en los que el bono baja hasta 0.
const TIME_BONUS_SLACK: float = 30.0
## Bono por completar una oleada sin recibir daño.
const NO_DAMAGE_BONUS: int = 300
## Cantidad máxima de partidas que se guardan (se borran las peores).
const MAX_SAVED: int = 100

## Ranking de todas las partidas: AVL ordenado por puntaje.
var ranking: AVLTree = AVLTree.new()
## Archivo que se usa para guardar y cargar (se puede cambiar en las pruebas).
var save_path: String = SAVE_PATH

## Máximo de partidas guardadas (variable para poder cambiarlo en las pruebas).
var max_saved: int = MAX_SAVED
## Puntaje de la partida en curso.
var score: int = 0
## Segundos jugados en la partida en curso (no cuenta el tiempo en pausa).
var run_time: float = 0.0
## Oleadas completadas en la partida en curso.
var waves_completed: int = 0
## Kills seguidas del combo actual y mejor combo de la partida.
var combo_kills: int = 0
var best_combo: int = 0

var _combo_time_left: float = 0.0
var _wave_active: bool = false
var _wave_time: float = 0.0
var _wave_fast_time: float = 0.0
var _wave_damaged: bool = false
var _running: bool = false
var _submitted: bool = false
var _last_result: Dictionary = {}


func _ready() -> void:
	load_from(save_path)


func _process(delta: float) -> void:
	# El árbol de escenas en pausa no ejecuta _process, así que la pausa no suma tiempo.
	if not _running:
		return
	run_time += delta
	if _wave_active:
		_wave_time += delta
	if combo_kills > 0:
		_combo_time_left -= delta
		if _combo_time_left <= 0.0:
			_break_combo()


## Empieza una partida nueva: puntaje, tiempo y oleadas en cero.
func start_run() -> void:
	score = 0
	run_time = 0.0
	waves_completed = 0
	combo_kills = 0
	best_combo = 0
	_combo_time_left = 0.0
	_wave_active = false
	_wave_time = 0.0
	_wave_damaged = false
	_submitted = false
	_last_result = {}
	_running = true
	score_changed.emit(score)
	combo_changed.emit(0, 1.0)


## Empieza una oleada. fast_time = segundos que tardan en salir todos los enemigos:
## si la oleada se termina en ese tiempo, el bono de rapidez es el máximo.
func start_wave(_wave_number: int, fast_time: float) -> void:
	_wave_active = true
	_wave_time = 0.0
	_wave_fast_time = fast_time
	_wave_damaged = false


## Multiplicador del combo para una cantidad de kills seguidas.
func multiplier_for(kills: int) -> float:
	var result: float = 1.0
	for tier in COMBO_TIERS:
		if kills >= tier[0]:
			result = tier[1]
	return result


## Multiplicador como texto corto: 1.5 -> "1.5", 2.0 -> "2".
func multiplier_text(multiplier: float) -> String:
	return String.num(multiplier, 1).trim_suffix(".0")


## Multiplicador del combo actual.
func get_multiplier() -> float:
	return multiplier_for(combo_kills)


## Qué tanto combo queda (1.0 = recién renovado, 0.0 = a punto de romperse).
func combo_fraction() -> float:
	return clampf(_combo_time_left / COMBO_WINDOW, 0.0, 1.0) if combo_kills > 0 else 0.0


## Suma los puntos de un enemigo derrotado (con el multiplicador del combo) y devuelve
## cuántos puntos sumó. Cada kill seguida renueva el tiempo del combo.
func add_kill(enemy_type: String) -> int:
	if not _running:
		return 0
	combo_kills += 1
	best_combo = maxi(best_combo, combo_kills)
	_combo_time_left = COMBO_WINDOW
	var base: int = POINTS_PER_KILL.get(enemy_type, DEFAULT_KILL_POINTS)
	var points: int = roundi(base * get_multiplier())
	add_points(points)
	combo_changed.emit(combo_kills, get_multiplier())
	return points


## El jugador recibió daño: se rompe el combo y esta oleada ya no cuenta como "sin daño".
func on_player_hit() -> void:
	_wave_damaged = true
	if combo_kills > 0:
		_break_combo()


func _break_combo() -> void:
	combo_kills = 0
	_combo_time_left = 0.0
	combo_changed.emit(0, 1.0)


## Bono de rapidez para una oleada que duró wave_time segundos (de 0 a TIME_BONUS_MAX, de 10 en 10).
func time_bonus(wave_time: float, fast_time: float) -> int:
	var late: float = maxf(0.0, wave_time - fast_time)
	var fraction: float = clampf(1.0 - late / TIME_BONUS_SLACK, 0.0, 1.0)
	return int(round(TIME_BONUS_MAX * fraction / 10.0)) * 10


## Suma el bono de una oleada completada: base + rapidez + sin daño. Devuelve el desglose.
func add_wave_bonus(wave_number: int) -> Dictionary:
	if not _running:
		return {}
	waves_completed += 1
	var bonus: Dictionary = {"base": WAVE_BONUS, "time": 0, "clean": 0}
	if _wave_active:
		bonus["time"] = time_bonus(_wave_time, _wave_fast_time)
		bonus["clean"] = 0 if _wave_damaged else NO_DAMAGE_BONUS
	bonus["total"] = bonus["base"] + bonus["time"] + bonus["clean"]
	_wave_active = false
	add_points(bonus["total"])
	wave_bonus_awarded.emit(wave_number, bonus)
	return bonus


## Suma puntos al puntaje de la partida en curso.
func add_points(amount: int) -> void:
	if not _running:
		return
	score += amount
	score_changed.emit(score)


## Termina la partida: la guarda en el ranking y devuelve el resultado:
##   {"score", "id", "rank" (1 = la mejor), "total" (partidas en el ranking),
##    "waves", "time", "victory", "new_record", "in_ranking", "best_combo", "nickname"}
## in_ranking es false si la partida fue tan mala que quedó fuera del límite de partidas guardadas.
## nickname es el nombre del jugador que se guarda junto a la partida.
## Solo guarda una vez por partida: si se llama de nuevo devuelve el mismo resultado.
func submit(victory: bool, nickname: String = "") -> Dictionary:
	if _submitted:
		return _last_result
	_submitted = true
	_running = false
	_break_combo()
	if victory:
		score += VICTORY_BONUS
		score_changed.emit(score)

	var value: Dictionary = {
		"waves": waves_completed,
		"time": run_time,
		"victory": victory,
		"nickname": nickname,
		"date": Time.get_datetime_string_from_system().replace("T", " ").substr(0, 16),
	}
	var id: int = ranking.insert(score, value)
	var position: int = ranking.rank(score, id)
	var in_ranking: bool = _trim_ranking(score, id)
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
		"in_ranking": in_ranking,
		"best_combo": best_combo,
		"nickname": nickname,
	}
	return _last_result


## Mantiene el ranking en max_saved partidas borrando la peor (la última del orden) hasta llegar al límite.
## Con el AVL, encontrar la peor es select(size) y borrarla es remove(): ambos O(log n).
## Devuelve false si la partida (key, id) fue de las borradas.
func _trim_ranking(key: int, id: int) -> bool:
	while ranking.size() > max_saved:
		var worst: Dictionary = ranking.select(ranking.size())
		ranking.remove(worst["key"], worst["id"])
	return ranking.find(key, id) != null


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
			"nickname": str(item.get("nickname", "")),
			"date": str(item.get("date", "")),
		}
		ranking.insert(int(item["score"]), value, int(item["id"]))
	while ranking.size() > max_saved:  # por si el archivo tiene más partidas que el límite
		var worst: Dictionary = ranking.select(ranking.size())
		ranking.remove(worst["key"], worst["id"])
	return true
