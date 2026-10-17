class_name MenuScreen
extends Control
## Base para los menús: crea el fondo oscuro y una columna centrada con título.
## PauseMenu y OptionsMenu heredan de aquí para no repetir código.


## Crea el diseño base y devuelve la columna donde se agregan los elementos.
func build_layout(title_text: String) -> VBoxContainer:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.6)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(240, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	return box


## Agrega un botón a la columna y lo conecta a la función callback.
func add_button(parent: Control, button_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = button_text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
