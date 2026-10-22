class_name EnemyHealthBar
extends RefCounted
## Ayudante estático: convierte el ProgressBar de un enemigo en una barra de salud
## (sin el texto de porcentaje, con relleno rojo que se vacía al recibir daño).

const BACKGROUND: Color = Color(0.12, 0.02, 0.03, 0.85)
const FILL: Color = Color(0.85, 0.12, 0.16)
const FILL_DARK: Color = Color(0.5, 0.06, 0.09)
const BORDER: Color = Color(0, 0, 0, 0.9)
## Ancho y alto de la barra en píxeles.
const WIDTH: float = 70.0
const HEIGHT: float = 12.0


static func style(bar: ProgressBar) -> void:
	bar.show_percentage = false  # quita el "100%"

	var background := StyleBoxFlat.new()
	background.bg_color = BACKGROUND
	background.set_border_width_all(1)
	background.border_color = BORDER

	var fill := StyleBoxFlat.new()
	fill.bg_color = FILL
	fill.border_width_bottom = 2  # franja oscura abajo: da relieve
	fill.border_color = FILL_DARK

	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

	# Sin el texto, la barra ya no tiene ancho propio (antes lo daba el "100%"),
	# así que se le da un tamaño fijo y se centra sobre el enemigo.
	bar.custom_minimum_size = Vector2(WIDTH, HEIGHT)
	bar.size = Vector2(WIDTH, HEIGHT)
	bar.position.x = -WIDTH / 2.0
	bar.z_index = 10  # siempre por encima del sprite
	bar.visible = true
