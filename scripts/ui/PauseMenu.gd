class_name PauseMenu
extends MenuScreen
## Menú de pausa: Continuar, Opciones, Salir.


func _ready() -> void:
	var box := build_layout("PAUSA")
	add_button(box, "Continuar", ScreenManager.pop_screen).grab_focus()
	add_button(box, "Opciones", func() -> void: ScreenManager.push_screen(OptionsMenu.new()))
	add_button(box, "Salir del juego", get_tree().quit)
