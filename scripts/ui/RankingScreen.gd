class_name RankingScreen
extends MenuScreen
## Pantalla con las 10 mejores partidas (el ranking que guarda el árbol AVL).
##
## Se apila con ScreenManager, igual que la pausa y las opciones: "Volver" o Esc la
## cierran y regresan a la pantalla anterior.
##
## Si se le pasa el resultado de la partida que acaba de terminar (el que devuelve
## ScoreManager.submit), esa fila se resalta; y si quedó fuera del top 10 se muestra
## aparte, con su posición real.

## Cuántas partidas se muestran.
const TOP_SIZE: int = 10
const COLUMNS: Array[String] = ["#", "PUNTAJE", "OLEADAS", "TIEMPO", "JUGADOR", ""]

var _last_result: Dictionary


## last_result: resultado de ScoreManager.submit() para resaltar esa partida (opcional).
func _init(last_result: Dictionary = {}) -> void:
	_last_result = last_result


func _ready() -> void:
	var box: VBoxContainer = build_layout("RANKING")
	# Fondo casi sólido: así no se transparenta el menú que haya debajo.
	(get_child(0) as ColorRect).color = Color(0.07, 0.07, 0.1, 0.97)

	var top: Array = ScoreManager.ranking.get_top(TOP_SIZE)
	if top.is_empty():
		var empty := Label.new()
		empty.text = "Todavía no hay partidas.\n¡Juega la primera!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(empty)
	else:
		box.add_child(_build_table(top))
		var count := Label.new()
		count.text = "Partidas registradas: %d" % ScoreManager.ranking.size()
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.add_theme_font_size_override("font_size", 15)
		count.add_theme_color_override("font_color", COLOR_PANEL_BORDER)
		box.add_child(count)

	add_button(box, "Volver", ScreenManager.pop_screen).grab_focus()


## Tabla con una fila por partida. Si la última partida quedó fuera del top, se agrega al final.
func _build_table(top: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS.size()
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 6)

	for title in COLUMNS:
		var header := Label.new()
		header.text = title
		header.add_theme_font_size_override("font_size", 15)
		header.add_theme_color_override("font_color", COLOR_PANEL_BORDER)
		grid.add_child(header)

	var last_id: int = _last_result.get("id", -1)
	var last_in_top: bool = false
	for i in top.size():
		var entry: Dictionary = top[i]
		var is_last: bool = entry["id"] == last_id
		last_in_top = last_in_top or is_last
		_add_row(grid, i + 1, entry, is_last)

	# La partida recién jugada quedó fuera del top: se muestra con su posición real.
	if last_id >= 0 and not last_in_top:
		var found: Variant = ScoreManager.ranking.find(_last_result["score"], last_id)
		if found != null:
			for _i in COLUMNS.size():
				var dots := Label.new()
				dots.text = "..." if _i == 0 else ""
				grid.add_child(dots)
			_add_row(grid, ScoreManager.ranking.rank(found["key"], found["id"]), found, true)
	return grid


func _add_row(grid: GridContainer, position: int, entry: Dictionary, highlight: bool) -> void:
	var value: Dictionary = entry["value"]
	var cells: Array[String] = [
		str(position),
		str(entry["key"]),
		str(value["waves"]),
		ScoreManager.format_time(value["time"]),
		value.get("nickname", "") if value.get("nickname", "") != "" else "---",
		"Victoria" if value["victory"] else "",
	]
	for text in cells:
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 17)
		if highlight:
			label.add_theme_color_override("font_color", COLOR_ACCENT)
		grid.add_child(label)
