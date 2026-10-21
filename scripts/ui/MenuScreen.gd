class_name MenuScreen
extends Control
## Base para los menús: oscurece la escena, centra un panel con título y aplica un
## estilo común (colores, bordes redondeados, botones grandes).
## PauseMenu, OptionsMenu, MainMenu y EndScreen heredan de aquí para no repetir código.
##
## Para cambiar el aspecto de TODOS los menús, basta con editar las constantes de abajo.

## Qué tan oscuro queda el fondo (0.0 = nada, 1.0 = negro total).
const DIM_ALPHA: float = 0.7
## Ancho mínimo del panel en píxeles.
const PANEL_MIN_WIDTH: float = 340.0
## Tamaño de la letra del título.
const TITLE_FONT_SIZE: int = 32
## Duración del fundido de entrada en segundos.
const FADE_TIME: float = 0.15

const COLOR_PANEL: Color = Color(0.09, 0.10, 0.14, 0.96)
const COLOR_PANEL_BORDER: Color = Color(0.35, 0.38, 0.52)
const COLOR_BUTTON: Color = Color(0.18, 0.20, 0.28)
const COLOR_BUTTON_HOVER: Color = Color(0.27, 0.32, 0.46)
const COLOR_BUTTON_PRESSED: Color = Color(0.12, 0.14, 0.20)
const COLOR_ACCENT: Color = Color(0.95, 0.75, 0.30)


## Crea el diseño base y devuelve la columna donde se agregan los elementos.
## Estructura: [fondo oscuro] + [CenterContainer > PanelContainer > VBoxContainer].
## El primer hijo de la columna es siempre el título.
func build_layout(title_text: String) -> VBoxContainer:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()  # los hijos heredan este estilo

	# Capa oscura que cubre toda la pantalla (y bloquea los clics hacia el juego).
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, DIM_ALPHA)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	# Centra el panel en la pantalla.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_MIN_WIDTH, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	box.add_child(title)
	box.add_child(HSeparator.new())

	# Aparece con un fundido suave.
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, FADE_TIME)
	return box


## Agrega un botón a la columna y lo conecta a la función callback.
func add_button(parent: Control, button_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


## Tema común de los menús: estilos de botón y tamaño de letra.
func _make_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox("normal", "Button", _button_style(COLOR_BUTTON))
	t.set_stylebox("hover", "Button", _button_style(COLOR_BUTTON_HOVER))
	t.set_stylebox("pressed", "Button", _button_style(COLOR_BUTTON_PRESSED))

	# Botón seleccionado con teclado: solo un borde dorado, sin relleno.
	var focus := _button_style(COLOR_BUTTON_HOVER)
	focus.draw_center = false
	focus.border_color = COLOR_ACCENT
	t.set_stylebox("focus", "Button", focus)

	t.set_font_size("font_size", "Button", 20)
	t.set_font_size("font_size", "Label", 20)
	return t


## Fondo redondeado para un botón.
func _button_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(8)
	s.set_border_width_all(2)
	s.border_color = color.lightened(0.15)
	s.set_content_margin_all(10)
	return s


## Estilo del panel central: oscuro, redondeado, con borde y sombra.
func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_PANEL
	s.set_corner_radius_all(16)
	s.set_border_width_all(2)
	s.border_color = COLOR_PANEL_BORDER
	s.set_content_margin_all(32)
	s.shadow_size = 16
	s.shadow_color = Color(0, 0, 0, 0.5)
	return s
