class_name EndScreen
extends MenuScreen
## Pantalla de fin de partida (derrota o victoria).
##
## Se apila con el ScreenManager, igual que el menú de pausa

## Escena del menú principal.
const MENU_SCENE: String = "res://scenes/MainMenu.tscn"

var _title: String


## title_text es el título grande que se muestra arriba.
func _init(title_text: String = "FIN DEL JUEGO") -> void:
	_title = title_text


func _ready() -> void:
	var box := build_layout(_title)
	(box.get_child(0) as Label).add_theme_font_size_override("font_size", 32)
	add_button(box, "Reintentar", _on_retry_pressed).grab_focus()
	add_button(box, "Menú principal", _on_main_menu_pressed)
	add_button(box, "Salir del juego", get_tree().quit)


## Esc normalmente "vuelve atrás" en la pila de pantallas, pero aquí no hay nada
## a lo que volver (la partida ya terminó), así que lo ignoramos.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


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
