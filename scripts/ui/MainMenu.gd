class_name MainMenu
extends MenuScreen
## Menú principal: Jugar, Controles y Salir.
##
## Hereda de MenuScreen (igual que PauseMenu y OptionsMenu) para reutilizar
## build_layout() y add_button(). Es la raíz de la escena MainMenu.tscn.
##
## Importante: este menú NO se apila en el ScreenManager (no pausa el juego);
## simplemente es una escena que se cambia por Main.tscn al pulsar Jugar.

## Escena del juego. Cambiar aquí si el nivel principal se mueve o se renombra.
const GAME_SCENE: String = "res://scenes/Main.tscn"

const CONTROLS_TEXT: String = "Mover: W A S D\nDisparar: clic izquierdo (hacia el mouse)\nUsar objeto: clic derecho (hacia el mouse)\nCambiar arma: Q\nCambiar objeto: E\nPausa / volver atrás: Esc"

var _controls_label: Label


func _ready() -> void:
	# En el menú principal Esc no debe abrir la pausa.
	ScreenManager.pause_enabled = false

	var game_title: String = ProjectSettings.get_setting("application/config/name", "Juego")
	var box := build_layout(game_title)

	# build_layout() crea primero un fondo semitransparente: aquí lo volvemos sólido.
	(get_child(0) as ColorRect).color = Color(0.07, 0.07, 0.1, 1.0)
	# El primer hijo de la columna es el título: lo hacemos más grande.
	(box.get_child(0) as Label).add_theme_font_size_override("font_size", 32)

	add_button(box, "Jugar", _on_play_pressed).grab_focus()
	add_button(box, "Controles", _on_controls_pressed)
	add_button(box, "Salir", get_tree().quit)

	_controls_label = Label.new()
	_controls_label.text = CONTROLS_TEXT
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.visible = false
	box.add_child(_controls_label)


## Empieza la partida.
func _on_play_pressed() -> void:
	ScreenManager.pause_enabled = true  # ya dentro del juego, Esc vuelve a abrir la pausa
	get_tree().change_scene_to_file(GAME_SCENE)


## Muestra u oculta la lista de controles.
func _on_controls_pressed() -> void:
	_controls_label.visible = not _controls_label.visible
