class_name MainMenu
extends MenuScreen
## Menú principal: Jugar, Ranking, Cambiar nombre, Controles y Salir.
##
## Hereda de MenuScreen (igual que PauseMenu y OptionsMenu) para reutilizar
## build_layout() y add_button(). Es la raíz de la escena MainMenu.tscn.
##
## Importante: este menú NO se apila en el ScreenManager (no pausa el juego);
## simplemente es una escena que se cambia por Main.tscn al pulsar Jugar.

## Escena del juego. Cambiar aquí si el nivel principal se mueve o se renombra.
const GAME_SCENE: String = "res://scenes/Main.tscn"

const CONTROLS_TEXT: String = "Mover: W A S D\nDisparar: clic izquierdo (hacia el mouse)\nUsar objeto: clic derecho (hacia el mouse)\nCambiar arma: Q\nCambiar objeto: E\nHabilidad (dash): Shift izquierdo\nPausa / volver atrás: Esc"

var _controls_label: Label
var _player_label: Label


func _ready() -> void:
	# En el menú principal Esc no debe abrir la pausa.
	ScreenManager.pause_enabled = false
	AudioManager.play_music("menu")

	var game_title: String = ProjectSettings.get_setting("application/config/name", "Juego")
	var box := build_layout(game_title)

	# build_layout() crea primero un fondo semitransparente: aquí lo volvemos sólido.
	(get_child(0) as ColorRect).color = Color(0.07, 0.07, 0.1, 1.0)
	# El primer hijo de la columna es el título: lo hacemos más grande.
	(box.get_child(0) as Label).add_theme_font_size_override("font_size", 32)

	_player_label = Label.new()
	_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_label.add_theme_color_override("font_color", COLOR_ACCENT)
	box.add_child(_player_label)
	_refresh_player_label()
	PlayerProfile.nickname_changed.connect(func(_name: String) -> void: _refresh_player_label())

	add_button(box, "Jugar", _on_play_pressed).grab_focus()
	add_button(box, "Ranking", _on_ranking_pressed)
	add_button(box, "Cambiar nombre", _on_change_name_pressed)
	add_button(box, "Controles", _on_controls_pressed)
	add_button(box, "Salir", get_tree().quit)

	_controls_label = Label.new()
	_controls_label.text = CONTROLS_TEXT
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.visible = false
	box.add_child(_controls_label)

	# Primera vez (o perfil borrado): se pide el nombre antes de jugar.
	if not PlayerProfile.has_nickname():
		_ask_nickname.call_deferred(true)


## Muestra "Jugador: nombre" arriba de los botones.
func _refresh_player_label() -> void:
	_player_label.text = "Jugador: %s" % PlayerProfile.nickname if PlayerProfile.has_nickname() else ""


func _ask_nickname(first_time: bool) -> void:
	ScreenManager.push_screen(NicknameScreen.new(first_time))


func _on_change_name_pressed() -> void:
	_ask_nickname(false)


## Empieza la partida.
func _on_play_pressed() -> void:
	if not PlayerProfile.has_nickname():
		_ask_nickname(true)
		return
	ScreenManager.pause_enabled = true  # ya dentro del juego, Esc vuelve a abrir la pausa
	get_tree().change_scene_to_file(GAME_SCENE)


## Abre el ranking de mejores partidas (se apila con ScreenManager; Esc o "Volver" lo cierran).
func _on_ranking_pressed() -> void:
	ScreenManager.push_screen(RankingScreen.new())


## Muestra u oculta la lista de controles.
func _on_controls_pressed() -> void:
	_controls_label.visible = not _controls_label.visible
