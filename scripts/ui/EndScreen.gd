class_name EndScreen
extends MenuScreen
## Pantalla de fin de partida (derrota o victoria).
##
## Se apila con el ScreenManager, igual que el menú de pausa.
## Muestra el puntaje obtenido y la posición que ocupó la partida en el ranking
## (la posición la calcula el árbol AVL con rank()).

## Escena del menú principal.
const MENU_SCENE: String = "res://scenes/MainMenu.tscn"

var _title: String
var _result: Dictionary
var _retry_button: Button


## title_text es el título grande que se muestra arriba.
## result es lo que devuelve ScoreManager.submit() (puntaje, posición, oleadas, tiempo).
func _init(title_text: String = "FIN DEL JUEGO", result: Dictionary = {}) -> void:
	_title = title_text
	_result = result


func _ready() -> void:
	var box := build_layout(_title)
	(box.get_child(0) as Label).add_theme_font_size_override("font_size", 32)
	if not _result.is_empty():
		_add_result(box)
	_retry_button = add_button(box, "Reintentar", _on_retry_pressed)
	_retry_button.grab_focus()
	add_button(box, "Ver ranking", _on_ranking_pressed)
	add_button(box, "Menú principal", _on_main_menu_pressed)
	add_button(box, "Salir del juego", get_tree().quit)
	# Al volver del ranking (esta pantalla se vuelve a mostrar) se recupera el foco del teclado.
	visibility_changed.connect(func() -> void:
		if visible:
			_retry_button.grab_focus())


## Puntaje, posición en el ranking, oleadas y tiempo de la partida que acaba de terminar.
func _add_result(box: VBoxContainer) -> void:
	var score := Label.new()
	score.text = "%s: %d" % [_result["nickname"] if _result.get("nickname", "") != "" else "Puntaje", _result["score"]]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 30)
	box.add_child(score)

	if _result["new_record"]:
		var record := Label.new()
		record.text = "¡NUEVO RÉCORD!"
		record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		record.add_theme_font_size_override("font_size", 24)
		record.add_theme_color_override("font_color", COLOR_ACCENT)
		box.add_child(record)

	var details := Label.new()
	var position_text: String = "Posición: #%d de %d" % [_result["rank"], _result["total"]]
	if not _result.get("in_ranking", true):
		position_text = "Fuera del ranking (solo se guardan las %d mejores)" % ScoreManager.MAX_SAVED
	details.text = "%s\nOleadas completadas: %d\nMejor combo: %d\nTiempo: %s" % [
		position_text, _result["waves"], _result.get("best_combo", 0), ScoreManager.format_time(_result["time"])
	]
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(details)


## Esc normalmente "vuelve atrás" en la pila de pantallas, pero aquí no hay nada
## a lo que volver (la partida ya terminó), así que lo ignoramos. Solo cuando esta
## pantalla es la visible: si el ranking está encima, Esc debe cerrar el ranking.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _on_ranking_pressed() -> void:
	ScreenManager.push_screen(RankingScreen.new(_result))


func _on_retry_pressed() -> void:
	_close_all_screens()
	ScreenManager.pause_enabled = true
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	_close_all_screens()
	get_tree().change_scene_to_file(MENU_SCENE)


## Vacía la pila de pantallas (el último pop_screen() reanuda el juego).
## Es necesario porque ScreenManager es un Autoload: la pila sobrevive al cambio de escena.
func _close_all_screens() -> void:
	while not ScreenManager.is_empty():
		ScreenManager.pop_screen()
