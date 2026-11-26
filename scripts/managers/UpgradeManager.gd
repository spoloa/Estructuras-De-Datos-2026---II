extends Node
## XP del jugador y árbol de mejoras (NaryTree) de la partida en curso.
##
## Se registra como Autoload con el nombre "UpgradeManager" (Proyecto > Configuración
## del proyecto > Globales), por eso este script NO declara class_name (igual que
## ScoreManager y ScreenManager).
##
## Flujo:
##   - Al morir, cada enemigo llama drop_xp(): suma XP al azar dentro de su intervalo.
##   - La tecla U abre la pantalla de mejoras (UpgradeScreen), apilada con ScreenManager.
##   - En esa pantalla se compra con buy(). Una mejora solo se puede comprar si su padre en
##     el árbol ya está "obtenido" (regla del árbol n-ario):
##        nivel 2 necesita el objeto base, y nivel 3 necesita el nivel 2.
##   - Player.gd lee las estadísticas ya mejoradas con stat(), sin modificar los .tres
##     (así las mejoras no se quedan pegadas al reiniciar la partida).
##   - GameFlow llama reset() al empezar la partida.

## Se emite cuando cambia la XP.
signal xp_changed(new_xp: int)
## Se emite al comprar una mejora.
signal upgrade_purchased(data: UpgradeData)

## Acción de teclado para abrir/cerrar la pantalla de mejoras (se crea sola si no existe).
const OPEN_ACTION: String = "open_upgrades"
## Tecla por defecto de esa acción.
const OPEN_KEY: Key = KEY_U

## Estado de un nodo del árbol para el jugador.
##   OWNED     -> ya lo tiene
##   AVAILABLE -> puede comprarlo ahora (su padre está obtenido y le alcanza la XP)
##   NO_XP     -> su padre está obtenido pero le falta XP
##   LOCKED    -> todavía no tiene lo anterior
enum Status { OWNED, AVAILABLE, NO_XP, LOCKED }

## XP actual del jugador.
var xp: int = 0
## Árbol de mejoras (raíz -> categorías -> objeto base -> nivel 2 -> nivel 3).
var tree: NaryTree

## Ids de las mejoras (nivel 2 y 3) ya compradas: {id: true}.
var _purchased: Dictionary = {}
## Nodo base (nivel 1) de cada objeto, por nombre: {item_key: NaryNode}. Para no recorrer el árbol.
var _base_nodes: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # la tecla debe funcionar con el juego en pausa
	_ensure_open_action()
	tree = UpgradeCatalog.build_tree()
	for node in tree.preorder():
		var data: UpgradeData = node.value
		if data.level == 1:
			_base_nodes[data.item_key] = node


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(OPEN_ACTION):
		return
	var top: Control = ScreenManager.top_screen()
	if top is UpgradeScreen:
		ScreenManager.pop_screen()
	elif top == null and ScreenManager.pause_enabled and get_player() != null:
		ScreenManager.push_screen(UpgradeScreen.new())
	else:
		return
	get_viewport().set_input_as_handled()


## Empieza una partida nueva: sin XP y sin mejoras compradas.
func reset() -> void:
	xp = 0
	_purchased.clear()
	xp_changed.emit(xp)


## Suma XP (no permite números negativos).
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	xp_changed.emit(xp)


## Un enemigo muerto suelta una cantidad al azar entre xp_min y xp_max (incluidos).
## Suma la XP y muestra "+N XP" flotando donde murió. Devuelve la XP soltada.
func drop_xp(source: Node2D, xp_min: int, xp_max: int) -> int:
	var amount: int = randi_range(mini(xp_min, xp_max), maxi(xp_min, xp_max))
	add_xp(amount)
	_spawn_popup(source, amount)
	return amount


## El jugador de la partida (null si no hay, por ejemplo en el menú principal).
func get_player() -> Player:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("player") as Player


## Nodo base (nivel 1) de un arma / objeto / habilidad, por su nombre. null si no existe.
func item_node(item_key: String) -> NaryNode:
	return _base_nodes.get(item_key)


## true si el jugador ya tiene ese nodo.
##   - estructural: siempre true
##   - nivel 1: true si el jugador tiene el arma / objeto / habilidad
##   - nivel 2 o 3: true si ya la compró
func is_owned(node: NaryNode) -> bool:
	var data: UpgradeData = node.value
	if data.level == 0:
		return true
	if data.level == 1:
		return _has_item(data)
	return _purchased.has(data.id)


## Estado del nodo para el jugador (ver Status).
func get_status(node: NaryNode) -> Status:
	if is_owned(node):
		return Status.OWNED
	var level: int = (node.value as UpgradeData).level
	if level <= 1 or node.parent == null or not is_owned(node.parent):
		return Status.LOCKED  # el nivel 1 no se compra: se consigue el objeto en el juego
	var data: UpgradeData = node.value
	return Status.AVAILABLE if xp >= data.cost else Status.NO_XP


## true si se puede comprar ahora: es una mejora (nivel 2 o 3), su padre está obtenido y alcanza la XP.
func can_buy(node: NaryNode) -> bool:
	var data: UpgradeData = node.value
	return data.level >= 2 and get_status(node) == Status.AVAILABLE


## Compra la mejora si se puede. Devuelve true si se compró.
func buy(node: NaryNode) -> bool:
	if not can_buy(node):
		return false
	var data: UpgradeData = node.value
	xp -= data.cost
	_purchased[data.id] = true
	xp_changed.emit(xp)
	upgrade_purchased.emit(data)
	return true


## Nivel más alto que tiene el jugador de ese objeto (0 si no lo tiene).
func level_of(item_key: String) -> int:
	var base: NaryNode = item_node(item_key)
	if base == null or not is_owned(base):
		return 0
	var best: int = 1
	for node in tree.preorder(base):
		var data: UpgradeData = node.value
		if _purchased.has(data.id):
			best = maxi(best, data.level)
	return best


## Valor de una estadística con las mejoras compradas ya sumadas.
## base es el valor del recurso (.tres). Si el objeto no tiene mejoras, devuelve base.
## Ejemplo: stat("Pistola", "damage", 2) -> 3 si ya compró "Punta hueca".
func stat(item_key: String, stat_name: String, base: float) -> float:
	var value: float = base
	var start: NaryNode = item_node(item_key)
	if start == null:
		return value
	for node in tree.preorder(start):
		var data: UpgradeData = node.value
		if _purchased.has(data.id) and data.mods.has(stat_name):
			value += float(data.mods[stat_name])
	return value


## ¿El jugador tiene el arma / objeto / habilidad de este nodo?
func _has_item(data: UpgradeData) -> bool:
	var player: Player = get_player()
	if player == null:
		return false
	match data.kind:
		UpgradeData.Kind.WEAPON:
			for i in player.inventory.size():
				var w: WeaponData = player.inventory.get_at(i)
				if w != null and w.weapon_name == data.item_key:
					return true
		UpgradeData.Kind.CONSUMABLE:
			for c in player.consumables:
				if c.display_name == data.item_key:
					return true
		UpgradeData.Kind.ABILITY:
			return player.ability != null and player.ability.display_name == data.item_key
	return false


## "+N XP" que sube y se desvanece donde murió el enemigo.
func _spawn_popup(source: Node2D, amount: int) -> void:
	if source == null or not source.is_inside_tree():
		return
	var label := Label.new()
	label.text = "+%d XP" % amount
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.85, 0.68, 0.30))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 100
	label.position = source.global_position + Vector2(-30, -60)
	source.get_tree().current_scene.add_child(label)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)


## Crea la acción de teclado si no existe en el Input Map (así no hay que tocar project.godot).
func _ensure_open_action() -> void:
	if InputMap.has_action(OPEN_ACTION):
		return
	InputMap.add_action(OPEN_ACTION)
	var key := InputEventKey.new()
	key.physical_keycode = OPEN_KEY
	InputMap.action_add_event(OPEN_ACTION, key)
