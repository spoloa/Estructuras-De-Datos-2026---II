extends Label

## Nodo Player (de él se lee la vida y las armas).
@export var player: Player
## Nodo WaveManager (de él se lee la oleada actual).
@export var wave_manager: WaveManager

# --- Paleta (cambiar aquí para cambiar los colores de todo el HUD) ---
const GOLD: Color = Color(0.85, 0.68, 0.30)
const GOLD_DIM: Color = Color(0.62, 0.50, 0.24)
const CREAM: Color = Color(0.95, 0.90, 0.75)
const PANEL_BG: Color = Color(0.07, 0.06, 0.08, 0.35)  # el último número es la opacidad (0 = invisible, 1 = sólido)
const PIP_OFF: Color = Color(0.25, 0.22, 0.20)
const HEALTH_BG: Color = Color(0.20, 0.04, 0.06)
const HEALTH_FILL: Color = Color(0.80, 0.12, 0.16)
const HEALTH_FILL_DARK: Color = Color(0.50, 0.06, 0.09)

## Separación del HUD con el borde de la pantalla.
const MARGIN: int = 16
## Ancho de la columna izquierda (barra de vida y arma).
const COLUMN_WIDTH: float = 180.0
## Tamaño del icono del objeto (corazón, bomba...) en píxeles.
const ICON_SIZE: float = 45.0

var _health_bar: ProgressBar
var _health_label: Label
var _weapon_name: Label
var _weapon_pips: HBoxContainer
var _item_icon: TextureRect
var _item_name: Label
var _item_bar: ProgressBar
var _item_status: Label
var _item_pips: HBoxContainer
var _item: ConsumableData  # objeto usable que se muestra (null = casilla vacía)
var _wave_value: Label
var _banner: Label
var _health_tween: Tween
var _banner_tween: Tween
var _last_health: int = -1


func _ready() -> void:
	text = ""
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()

	# Estructura: margen > fila [ columna izquierda | espacio | columna derecha ]
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(margin)

	var row := HBoxContainer.new()
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	row.add_child(left)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var right := VBoxContainer.new()
	row.add_child(right)

	_build_health(left)
	_build_weapon(left)
	_build_item(left)
	_build_wave(right)
	_build_banner()
	_ignore_mouse(self)  # el HUD nunca debe bloquear clics

	_connect_signals()
	_show_banner("¡PREPÁRATE!")


# ---------------------------------------------------------------------------
# Construcción de la interfaz
# ---------------------------------------------------------------------------

## Barra de vida roja con un corazón y el número de corazones ("3 / 5") dentro.
func _build_health(parent: Control) -> void:
	var frame := _make_frame()
	parent.add_child(frame)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(COLUMN_WIDTH - 20.0, 32)
	_health_bar.show_percentage = false
	_health_bar.min_value = 0

	var background := StyleBoxFlat.new()
	background.bg_color = HEALTH_BG
	background.set_border_width_all(2)
	background.border_color = Color(0, 0, 0, 0.8)

	var fill := StyleBoxFlat.new()
	fill.bg_color = HEALTH_FILL
	fill.border_width_bottom = 5  # franja oscura abajo: da relieve a la barra
	fill.border_color = HEALTH_FILL_DARK

	_health_bar.add_theme_stylebox_override("background", background)
	_health_bar.add_theme_stylebox_override("fill", fill)
	frame.add_child(_health_bar)

	# Corazón dibujado a la izquierda, dentro de la barra.
	var heart := HeartIcon.new()
	heart.custom_minimum_size = Vector2(22, 22)
	heart.size = Vector2(22, 22)
	heart.position = Vector2(8, 5)
	_health_bar.add_child(heart)

	# Texto centrado dentro de la barra.
	_health_label = Label.new()
	_health_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_label.add_theme_font_size_override("font_size", 18)
	_health_label.add_theme_color_override("font_color", CREAM)
	_health_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_health_label.add_theme_constant_override("outline_size", 4)
	_health_bar.add_child(_health_label)


## Arma equipada + una casilla por cada arma del inventario (la dorada es la equipada).
func _build_weapon(parent: Control) -> void:
	var frame := _make_frame()
	parent.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	frame.add_child(col)

	col.add_child(_make_caption("ARMA"))

	_weapon_name = Label.new()
	_weapon_name.add_theme_font_size_override("font_size", 22)
	_weapon_name.add_theme_color_override("font_color", CREAM)
	col.add_child(_weapon_name)

	var bottom := HBoxContainer.new()
	col.add_child(bottom)

	_weapon_pips = HBoxContainer.new()
	_weapon_pips.add_theme_constant_override("separation", 4)
	_weapon_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(_weapon_pips)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)

	bottom.add_child(_make_caption("[Q] CAMBIAR"))


## Objeto usable (corazón): icono, nombre, barra de recarga y tecla para usarlo.
func _build_item(parent: Control) -> void:
	var frame := _make_frame()
	parent.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	frame.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	header.add_child(_make_caption("OBJETO"))
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	header.add_child(_make_caption("[E] CAMBIAR"))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)

	_item_icon = TextureRect.new()
	_item_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_item_icon)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)

	_item_name = Label.new()
	_item_name.add_theme_font_size_override("font_size", 18)
	_item_name.add_theme_color_override("font_color", CREAM)
	info.add_child(_item_name)

	# Barra de recarga: se va llenando hasta que el objeto está listo.
	_item_bar = ProgressBar.new()
	_item_bar.custom_minimum_size = Vector2(0, 8)
	_item_bar.show_percentage = false
	_item_bar.min_value = 0.0
	_item_bar.max_value = 1.0
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = PIP_OFF
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = GOLD
	_item_bar.add_theme_stylebox_override("background", bar_bg)
	_item_bar.add_theme_stylebox_override("fill", bar_fill)
	info.add_child(_item_bar)

	_item_status = _make_caption("")
	_item_status.add_theme_font_size_override("font_size", 14)
	info.add_child(_item_status)

	# Una casilla por objeto del inventario (dorada = seleccionado).
	_item_pips = HBoxContainer.new()
	_item_pips.add_theme_constant_override("separation", 4)
	info.add_child(_item_pips)

	_refresh_item()


## Actualiza icono, nombre y estado del panel de objeto.
func _refresh_item() -> void:
	_rebuild_item_pips()
	if _item == null:
		_item_icon.texture = null
		_item_name.text = "VACÍO"
		_item_name.modulate = Color(1, 1, 1, 0.4)
		_item_bar.value = 0.0
		_item_status.text = "---"
		return
	_item_icon.texture = _item.get_icon()
	_item_name.text = _item.display_name.to_upper()
	_item_name.modulate = Color.WHITE
	_update_item_cooldown()


## Dibuja una casilla por objeto del inventario (dorada = el seleccionado).
func _rebuild_item_pips() -> void:
	if _item_pips == null:
		return
	for pip in _item_pips.get_children():
		_item_pips.remove_child(pip)
		pip.queue_free()
	if player == null:
		return
	var selected: int = player.consumables.find(_item)
	for i in player.consumables.size():
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.color = GOLD if i == selected else PIP_OFF
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_item_pips.add_child(pip)


## Barra y texto de recarga (se llama cada frame desde _process).
func _update_item_cooldown() -> void:
	if _item == null or player == null:
		return
	var left: float = player.get_item_cooldown_left(_item)
	if left > 0.0 and _item.cooldown > 0.0:
		_item_bar.value = 1.0 - left / _item.cooldown
		_item_status.text = "%.1fs" % left
		_item_icon.modulate = Color(0.45, 0.45, 0.45)  # apagado mientras recarga
	else:
		_item_bar.value = 1.0
		_item_status.text = "LISTO"
		_item_icon.modulate = Color.WHITE


func _process(_delta: float) -> void:
	_update_item_cooldown()


## Panel de la oleada actual (esquina superior derecha).
func _build_wave(parent: Control) -> void:
	var frame := _make_frame()
	frame.custom_minimum_size = Vector2(150, 0)
	parent.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	frame.add_child(col)

	var caption := _make_caption("OLEADA")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(caption)

	_wave_value = Label.new()
	_wave_value.text = "- / -"
	_wave_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_value.add_theme_font_size_override("font_size", 30)
	_wave_value.add_theme_color_override("font_color", CREAM)
	col.add_child(_wave_value)


## Aviso grande que aparece arriba al centro y se desvanece solo.
func _build_banner() -> void:
	var box := MarginContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("margin_top", 110)
	add_child(box)

	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_banner.add_theme_font_size_override("font_size", 40)
	_banner.add_theme_color_override("font_color", GOLD)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.modulate.a = 0.0
	box.add_child(_banner)


## Marco retro: fondo oscuro, borde dorado, esquinas rectas y sombra desplazada.
func _make_frame() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 2
	style.shadow_offset = Vector2(3, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel


## Rótulo pequeño en dorado apagado (ARMA, OLEADA...).
func _make_caption(caption_text: String) -> Label:
	var label := Label.new()
	label.text = caption_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", GOLD_DIM)
	return label


## Tema del HUD: letra monoespaciada (Courier/Consolas) en negrita.
## Si el sistema no tiene esas fuentes, Godot usa la suya por defecto.
func _make_theme() -> Theme:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Courier New", "Consolas", "Lucida Console", "monospace"])
	font.font_weight = 700
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 18
	# Contorno oscuro en todos los textos: se leen bien aunque el panel sea transparente.
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))
	t.set_constant("outline_size", "Label", 4)
	return t


## Hace que ningún elemento del HUD capture el mouse.
func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------

func _connect_signals() -> void:
	if player == null:
		push_warning("HUD: falta asignar el Player en el Inspector")
	else:
		player.health_changed.connect(_on_health_changed)
		player.weapon_changed.connect(_on_weapon_changed)
		player.consumable_added.connect(_on_consumable_added)
		player.consumable_selected.connect(_on_consumable_selected)
		_item = player.get_selected_consumable()
		_refresh_item()
		# El Player ya se inicializó antes que el HUD, así que leemos su estado actual.
		_on_health_changed(player.health, player.max_health)
		_on_weapon_changed(player.weapon, 0, player.inventory.size())

	if wave_manager == null:
		push_warning("HUD: falta asignar el WaveManager en el Inspector")
	else:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)


## La barra se llena/vacía con una animación corta y parpadea al recibir daño.
func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_label.text = "%d / %d" % [current, maximum]

	if _health_tween != null:
		_health_tween.kill()
	_health_tween = create_tween()
	_health_tween.tween_property(_health_bar, "value", float(current), 0.25)

	if _last_health >= 0 and current < _last_health:
		_health_bar.modulate = Color(1.8, 1.8, 1.8)  # destello al recibir daño
		_health_tween.parallel().tween_property(_health_bar, "modulate", Color.WHITE, 0.25)
	_last_health = current


## Muestra el nombre del arma y dibuja una casilla por arma (dorada = equipada).
func _on_weapon_changed(weapon: WeaponData, slot: int, total: int) -> void:
	_weapon_name.text = "SIN ARMA" if weapon == null else weapon.weapon_name.to_upper()

	for pip in _weapon_pips.get_children():
		_weapon_pips.remove_child(pip)
		pip.queue_free()
	for i in total:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.color = GOLD if i == slot else PIP_OFF
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_weapon_pips.add_child(pip)


## Al recoger un objeto usable se muestra en el panel y se avisa con el banner.
func _on_consumable_added(data: ConsumableData) -> void:
	_refresh_item()
	_show_banner("¡%s!  [E] CAMBIAR · [CLIC DER.] USAR" % data.display_name.to_upper())


## Al cambiar de objeto con la tecla E se actualiza el panel.
func _on_consumable_selected(data: ConsumableData) -> void:
	_item = data
	_refresh_item()


## Cuando empieza una oleada, el WaveManager ya sacó esa oleada de su cola (Queue),
## así que las que quedan en la cola + la actual = total de oleadas.
func _on_wave_started(number: int) -> void:
	var total: int = number + wave_manager.waves.size()
	_wave_value.text = "%d / %d" % [number, total]
	_show_banner("¡OLEADA %d!" % number)


func _on_all_waves_completed() -> void:
	_wave_value.text = "¡LISTO!"


## Muestra un aviso grande que se desvanece solo.
func _show_banner(message: String) -> void:
	_banner.text = message
	_banner.modulate.a = 1.0
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.4)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


## Corazón dibujado con dos círculos y un triángulo (no necesita imagen ni fuente).
class HeartIcon extends Control:
	var color: Color = Color(1.0, 0.88, 0.88)

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		draw_circle(Vector2(s * 0.30, s * 0.32), s * 0.26, color)
		draw_circle(Vector2(s * 0.70, s * 0.32), s * 0.26, color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(s * 0.06, s * 0.42),
			Vector2(s * 0.94, s * 0.42),
			Vector2(s * 0.50, s * 0.94),
		]), color)
