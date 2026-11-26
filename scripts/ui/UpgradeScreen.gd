class_name UpgradeScreen
extends MenuScreen
## Pantalla de mejoras: dos mini ventanas lado a lado.
##   Ventana 1 "TUS MEJORAS": las armas, objetos y habilidades que tienes (al estilo The
##             Binding of Isaac), con su nivel y sus estadísticas actuales.
##   Ventana 2 "ÁRBOL DE MEJORAS": todas las mejoras posibles, recorriendo el árbol n-ario
##             de UpgradeManager. Se compran con clic usando la XP.
##
## Se apila con ScreenManager (igual que la pausa y el ranking) y se abre/cierra con la
## tecla U (ver UpgradeManager.gd). Esc o "Cerrar" también la cierran.

## Tamaño de cada casilla de la ventana 1 en píxeles.
const SLOT_SIZE: float = 64.0
## Ancho de cada botón de mejora de la ventana 2.
const NODE_WIDTH: float = 132.0
const NODE_HEIGHT: float = 52.0
## Ancho de las ventanas.
const OWNED_WIDTH: float = 300.0
const TREE_WIDTH: float = 580.0
## Alto de la zona con scroll del árbol.
const TREE_HEIGHT: float = 215.0

const PIP_OFF: Color = Color(0.25, 0.22, 0.20)
const COLOR_CREAM: Color = Color(0.95, 0.90, 0.75)
const COLOR_DIM: Color = Color(0.45, 0.47, 0.55)

var _xp_label: Label
var _windows_row: HBoxContainer
var _slots_grid: GridContainer
var _owned_detail: Label
var _tree_box: VBoxContainer
var _tree_detail: Label
var _message: String = ""


func _ready() -> void:
	var box: VBoxContainer = build_layout("MEJORAS")
	# Panel un poco menos acolchado para que quepan las dos ventanas.
	var panel := get_child(1).get_child(0) as PanelContainer
	var style: StyleBoxFlat = _panel_style()
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)

	_xp_label = Label.new()
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.add_theme_color_override("font_color", COLOR_ACCENT)
	box.add_child(_xp_label)

	_windows_row = HBoxContainer.new()
	_windows_row.add_theme_constant_override("separation", 16)
	box.add_child(_windows_row)
	_build_owned_window()
	_build_tree_window()

	add_button(box, "Cerrar  [U]", ScreenManager.pop_screen).grab_focus()
	_refresh()


# ---------------------------------------------------------------------------
# Construcción de las ventanas
# ---------------------------------------------------------------------------

## Crea una mini ventana (marco dorado + título) y devuelve su columna interior.
func _make_window(title: String, width: float) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(width, 0)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.07, 0.10, 0.9)
	s.set_corner_radius_all(6)
	s.set_border_width_all(2)
	s.border_color = COLOR_ACCENT.darkened(0.3)
	s.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel", s)
	_windows_row.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	frame.add_child(col)
	var caption := Label.new()
	caption.text = title
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color", COLOR_ACCENT.darkened(0.2))
	col.add_child(caption)
	col.add_child(HSeparator.new())
	return col


func _build_owned_window() -> void:
	var col: VBoxContainer = _make_window("TUS MEJORAS", OWNED_WIDTH)
	_slots_grid = GridContainer.new()
	_slots_grid.columns = 4
	_slots_grid.add_theme_constant_override("h_separation", 10)
	_slots_grid.add_theme_constant_override("v_separation", 10)
	col.add_child(_slots_grid)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	col.add_child(HSeparator.new())
	_owned_detail = _make_detail(OWNED_WIDTH - 24.0)
	col.add_child(_owned_detail)


func _build_tree_window() -> void:
	var col: VBoxContainer = _make_window("ÁRBOL DE MEJORAS", TREE_WIDTH)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, TREE_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_tree_box = VBoxContainer.new()
	_tree_box.add_theme_constant_override("separation", 6)
	_tree_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_tree_box)

	col.add_child(HSeparator.new())
	_tree_detail = _make_detail(TREE_WIDTH - 24.0)
	col.add_child(_tree_detail)


func _make_detail(width: float) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(width, 72)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_CREAM)
	return label


# ---------------------------------------------------------------------------
# Contenido (se reconstruye después de cada compra)
# ---------------------------------------------------------------------------

func _refresh() -> void:
	_xp_label.text = "XP: %d        [U] o [Esc] para cerrar" % UpgradeManager.xp
	_clear(_slots_grid)
	_clear(_tree_box)
	_fill_owned()
	_fill_tree()
	_owned_detail.text = "Pasa el mouse sobre un objeto para ver sus estadísticas."
	_tree_detail.text = _message if _message != "" else "Pasa el mouse sobre una mejora para ver qué hace. Clic para comprarla."


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


## Ventana 1: una casilla por cada arma, objeto y habilidad que tiene el jugador.
func _fill_owned() -> void:
	var player: Player = UpgradeManager.get_player()
	if player == null:
		return
	for i in player.inventory.size():
		var w: WeaponData = player.inventory.get_at(i)
		var tex: Texture2D = w.icon if w.icon != null else ItemPickup.WEAPON_TEXTURE
		_add_slot(w, w.weapon_name, UpgradeData.Kind.WEAPON, tex)
	for c in player.consumables:
		_add_slot(c, c.display_name, UpgradeData.Kind.CONSUMABLE, c.get_icon(), player.get_consumable_count(c))
	if player.ability != null:
		_add_slot(player.ability, player.ability.display_name, UpgradeData.Kind.ABILITY, player.ability.get_icon())
	if _slots_grid.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "Todavía no tienes nada."
		_slots_grid.add_child(empty)


func _add_slot(entity: Resource, key: String, kind: UpgradeData.Kind, texture: Texture2D, count: int = -1) -> void:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)
	_slots_grid.add_child(cell)

	var button := Button.new()
	button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	button.icon = texture
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", int(SLOT_SIZE) - 14)
	button.add_theme_stylebox_override("normal", _flat(COLOR_BUTTON, COLOR_PANEL_BORDER))
	button.add_theme_stylebox_override("hover", _flat(COLOR_BUTTON_HOVER, COLOR_ACCENT))
	button.add_theme_stylebox_override("pressed", _flat(COLOR_BUTTON_PRESSED, COLOR_ACCENT))
	var show_detail := func() -> void: _owned_detail.text = _owned_text(entity, key, kind)
	button.mouse_entered.connect(show_detail)
	button.focus_entered.connect(show_detail)
	cell.add_child(button)

	# Cantidad de unidades (solo objetos: corazón, bomba) abajo a la derecha de la casilla.
	if count >= 0:
		var badge := Label.new()
		badge.text = "x%d" % count
		badge.add_theme_font_size_override("font_size", 15)
		badge.add_theme_color_override("font_color", COLOR_CREAM)
		badge.add_theme_color_override("font_outline_color", Color.BLACK)
		badge.add_theme_constant_override("outline_size", 5)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 4)
		button.add_child(badge)

	# Tres casillitas: cuántos niveles tienes de este objeto (igual que en el HUD).
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 4)
	cell.add_child(pips)
	var level: int = UpgradeManager.level_of(key)
	for n in range(1, 4):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.color = COLOR_ACCENT if n <= level else PIP_OFF
		pips.add_child(pip)


## Ventana 2: recorre las categorías del árbol y, por cada objeto, dibuja su cadena de niveles.
## (En este catálogo cada objeto es una cadena: nivel 1 -> nivel 2 -> nivel 3.)
func _fill_tree() -> void:
	for category in UpgradeManager.tree.root.children:
		var header := Label.new()
		header.text = (category.value as UpgradeData).display_name.to_upper()
		header.add_theme_color_override("font_color", COLOR_ACCENT)
		_tree_box.add_child(header)
		for item in category.children:
			_add_item_row(item)


func _add_item_row(item: NaryNode) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_tree_box.add_child(row)

	var name_label := Label.new()
	name_label.text = (item.value as UpgradeData).display_name
	name_label.custom_minimum_size = Vector2(96, 0)
	name_label.add_theme_color_override("font_color", COLOR_CREAM if UpgradeManager.is_owned(item) else COLOR_DIM)
	row.add_child(name_label)

	var node: NaryNode = item
	while node != null:
		_add_node_button(row, node)
		if node.is_leaf():
			break
		var arrow := Label.new()
		arrow.text = ">"
		arrow.add_theme_color_override("font_color", COLOR_DIM)
		row.add_child(arrow)
		node = node.children[0]


func _add_node_button(row: HBoxContainer, node: NaryNode) -> void:
	var data: UpgradeData = node.value
	var status: int = UpgradeManager.get_status(node)

	var bg: Color
	var border: Color
	var font: Color
	var line2: String
	match status:
		UpgradeManager.Status.OWNED:
			bg = Color(0.30, 0.24, 0.10)
			border = COLOR_ACCENT
			font = COLOR_CREAM
			line2 = "BASE" if data.level == 1 else "COMPRADA"
		UpgradeManager.Status.AVAILABLE:
			bg = COLOR_BUTTON_HOVER
			border = COLOR_ACCENT
			font = Color.WHITE
			line2 = "%d XP" % data.cost
		UpgradeManager.Status.NO_XP:
			bg = COLOR_BUTTON
			border = Color(0.6, 0.25, 0.25)
			font = Color(0.9, 0.5, 0.5)
			line2 = "%d XP" % data.cost
		_:
			bg = Color(0.12, 0.13, 0.17)
			border = Color(0.22, 0.24, 0.32)
			font = COLOR_DIM
			line2 = "SIN OBTENER" if data.level == 1 else "%d XP" % data.cost

	var button := Button.new()
	button.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
	button.text = "Nivel 1\n%s" % line2 if data.level == 1 else "%s\n%s" % [data.display_name, line2]
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 14)
	button.disabled = not UpgradeManager.can_buy(node)
	for state in ["normal", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, _flat(bg, border))
	button.add_theme_stylebox_override("hover", _flat(bg.lightened(0.15), border))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, font)
	button.pressed.connect(_on_node_pressed.bind(node))
	button.mouse_entered.connect(func() -> void: _tree_detail.text = _node_text(node))
	row.add_child(button)


func _on_node_pressed(node: NaryNode) -> void:
	var data: UpgradeData = node.value
	if UpgradeManager.buy(node):
		_message = "¡Compraste «%s»! %s" % [data.display_name, data.description]
	else:
		_message = "No se pudo comprar «%s»." % data.display_name
	_refresh()


# ---------------------------------------------------------------------------
# Textos
# ---------------------------------------------------------------------------

## Detalle de un objeto que tienes: nivel, estadísticas actuales y mejoras compradas.
func _owned_text(entity: Resource, key: String, kind: UpgradeData.Kind) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s  (nivel %d/3)" % [key.to_upper(), UpgradeManager.level_of(key)])
	if kind == UpgradeData.Kind.CONSUMABLE:
		lines.append("Unidades: %d" % UpgradeManager.get_player().get_consumable_count(entity))
	lines.append(_stats_text(entity, key, kind))
	var base: NaryNode = UpgradeManager.item_node(key)
	if base != null:
		for node in UpgradeManager.tree.preorder(base):
			var data: UpgradeData = node.value
			if data.level >= 2 and UpgradeManager.is_owned(node):
				lines.append("• %s" % data.display_name)
	return "\n".join(lines)


## Estadísticas actuales (ya con las mejoras compradas).
func _stats_text(entity: Resource, key: String, kind: UpgradeData.Kind) -> String:
	var parts: PackedStringArray = PackedStringArray()
	match kind:
		UpgradeData.Kind.WEAPON:
			var w: WeaponData = entity
			parts.append("Daño %d" % roundi(UpgradeManager.stat(key, "damage", w.damage)))
			parts.append("Cadencia %.1f/s" % UpgradeManager.stat(key, "fire_rate", w.fire_rate))
			var pellets: int = roundi(UpgradeManager.stat(key, "bullets_per_shot", w.bullets_per_shot))
			if pellets > 1:
				parts.append("Perdigones %d" % pellets)
			if w.attack_type == WeaponData.AttackType.MELEE:
				parts.append("Alcance %d" % roundi(UpgradeManager.stat(key, "melee_range", w.melee_range)))
			elif w.rocket_scene != null:
				parts.append("Explosión %d" % roundi(UpgradeManager.stat(key, "blast_radius", w.blast_radius)))
		UpgradeData.Kind.CONSUMABLE:
			var c: ConsumableData = entity
			if c.effect == ConsumableData.Effect.HEAL:
				parts.append("Cura %d" % roundi(UpgradeManager.stat(key, "heal_amount", c.heal_amount)))
			else:
				parts.append("Daño %d" % roundi(UpgradeManager.stat(key, "damage", c.damage)))
				parts.append("Radio %d" % roundi(UpgradeManager.stat(key, "blast_radius", c.blast_radius)))
			parts.append("Recarga %.0fs" % maxf(1.0, UpgradeManager.stat(key, "cooldown", c.cooldown)))
		UpgradeData.Kind.ABILITY:
			var a: AbilityData = entity
			parts.append("Recarga %.1fs" % maxf(0.5, UpgradeManager.stat(key, "cooldown", a.cooldown)))
			parts.append("Distancia %d" % roundi(UpgradeManager.stat(key, "dash_distance", a.dash_distance)))
	return " · ".join(parts)


## Detalle de un nodo del árbol: qué hace, cuánto cuesta y por qué no se puede comprar.
func _node_text(node: NaryNode) -> String:
	var data: UpgradeData = node.value
	var title: String = "%s  (nivel %d)" % [data.display_name, data.level]
	match UpgradeManager.get_status(node):
		UpgradeManager.Status.OWNED:
			return "%s\n%s\nYa la tienes." % [title, data.description]
		UpgradeManager.Status.AVAILABLE:
			return "%s\n%s\nCosto: %d XP. Clic para comprarla." % [title, data.description, data.cost]
		UpgradeManager.Status.NO_XP:
			return "%s\n%s\nTe faltan %d XP." % [title, data.description, data.cost - UpgradeManager.xp]
	var parent: UpgradeData = node.parent.value
	var need: String = "Primero consigue %s." % parent.item_key if parent.level == 1 else "Primero compra «%s»." % parent.display_name
	return "%s\n%s\nBloqueada. %s" % [title, data.description, need]


func _flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(6)
	s.set_border_width_all(2)
	s.border_color = border
	s.set_content_margin_all(6)
	return s
