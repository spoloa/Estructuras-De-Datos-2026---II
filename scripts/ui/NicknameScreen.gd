class_name NicknameScreen
extends MenuScreen
## Pantalla para escribir el nickname del jugador.
##
## - Primera vez que se abre el juego: no se puede cerrar sin elegir un nombre.
## - Desde "Cambiar nombre": se puede cancelar (botón o Esc).
## El nombre se guarda en PlayerProfile y queda para las próximas veces.

var _first_time: bool
var _name_field: LineEdit
var _hint: Label


## first_time = true cuando todavía no hay nickname (no deja cancelar).
func _init(first_time: bool = false) -> void:
	_first_time = first_time


func _ready() -> void:
	var box: VBoxContainer = build_layout("¿CÓMO TE LLAMAS?" if _first_time else "CAMBIAR NOMBRE")
	(get_child(0) as ColorRect).color = Color(0.07, 0.07, 0.1, 0.97)

	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Tu nickname"
	_name_field.max_length = PlayerProfile.MAX_LENGTH
	_name_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_field.custom_minimum_size = Vector2(0, 52)
	_name_field.text = PlayerProfile.nickname
	_name_field.select_all_on_focus = true
	_name_field.text_submitted.connect(func(_text: String) -> void: _on_accept())
	_name_field.text_changed.connect(func(_text: String) -> void: _hint.text = "")
	box.add_child(_name_field)

	_hint = Label.new()
	_hint.text = ""
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", COLOR_ACCENT)
	box.add_child(_hint)

	var info := Label.new()
	info.text = "Aparecerá en el ranking.\n%d a %d caracteres: letras, números, espacio, - y _" % [PlayerProfile.MIN_LENGTH, PlayerProfile.MAX_LENGTH]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 15)
	info.add_theme_color_override("font_color", COLOR_PANEL_BORDER)
	box.add_child(info)

	add_button(box, "Aceptar", _on_accept)
	if not _first_time:
		add_button(box, "Cancelar", ScreenManager.pop_screen)

	_name_field.grab_focus.call_deferred()
	_name_field.caret_column = _name_field.text.length()


## Esc cancela solo si no es la primera vez (si no, no hay a dónde volver).
func _unhandled_name_field(event: InputEvent) -> void:
	if _first_time and visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _on_accept() -> void:
	if not PlayerProfile.set_nickname(_name_field.text):
		_hint.text = "Escribe al menos %d letras o números" % PlayerProfile.MIN_LENGTH
		_name_field.grab_focus()
		return
	ScreenManager.pop_screen()
