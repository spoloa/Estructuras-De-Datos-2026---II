class_name UpgradeCatalog
extends RefCounted
## Catálogo de mejoras: construye el árbol n-ario (NaryTree) con todas las armas, objetos
## y habilidades y sus 3 niveles.
##
## Para AGREGAR o BALANCEAR mejoras solo hay que editar las tablas de abajo (WEAPONS,
## CONSUMABLES, ABILITIES). Cada entrada es:
##   "Nombre del objeto": [ nivel 2, nivel 3 ]
## y cada nivel es:
##   {"name": ..., "desc": ..., "cost": XP, "mods": {"stat": valor_a_sumar}}
##
## El "Nombre del objeto" debe ser EXACTAMENTE el de su recurso (.tres):
##   armas       -> WeaponData.weapon_name      (Pistola, Escopeta, Bazuca, Bate)
##   objetos     -> ConsumableData.display_name (Corazón, Bomba)
##   habilidades -> AbilityData.display_name    (Dash)
##
## Stats que entiende el juego (las lee Player.gd a través de UpgradeManager.stat()):
##   armas:       damage, fire_rate, bullets_per_shot, blast_radius, melee_range
##   objetos:     heal_amount, cooldown, damage, blast_radius
##   habilidades: cooldown, dash_distance
## El nivel 1 (base) es lo que ya está en los .tres y no tiene mods.

const WEAPONS: Dictionary = {
	"Pistola": [
		{"name": "Gatillo fino", "desc": "Dispara más rápido.", "cost": 15, "mods": {"fire_rate": 1.0}},
		{"name": "Punta hueca", "desc": "Cada bala hace +1 de daño.", "cost": 35, "mods": {"damage": 1}},
	],
	"Escopeta": [
		{"name": "Cartuchos extra", "desc": "+2 perdigones por disparo.", "cost": 20, "mods": {"bullets_per_shot": 2}},
		{"name": "Recámara rápida", "desc": "Más cadencia y +1 de daño por perdigón.", "cost": 40, "mods": {"fire_rate": 0.3, "damage": 1}},
	],
	"Bazuca": [
		{"name": "Ojiva grande", "desc": "Explosión más ancha y +3 de daño.", "cost": 25, "mods": {"blast_radius": 60.0, "damage": 3}},
		{"name": "Recarga turbo", "desc": "Dispara más seguido.", "cost": 45, "mods": {"fire_rate": 0.25}},
	],
	"Bate": [
		{"name": "Madera maciza", "desc": "+3 de daño por golpe.", "cost": 15, "mods": {"damage": 3}},
		{"name": "Swing amplio", "desc": "Más alcance y más cadencia.", "cost": 35, "mods": {"melee_range": 60.0, "fire_rate": 0.5}},
	],
}

const CONSUMABLES: Dictionary = {
	"Corazón": [
		{"name": "Corazón fuerte", "desc": "Se recarga 3 segundos más rápido.", "cost": 15, "mods": {"cooldown": -3.0}},
		{"name": "Corazón doble", "desc": "Cura +1 corazón al usarlo.", "cost": 35, "mods": {"heal_amount": 1}},
	],
	"Bomba": [
		{"name": "Mecha corta", "desc": "Se recarga 6 segundos más rápido.", "cost": 20, "mods": {"cooldown": -6.0}},
		{"name": "Carga mayor", "desc": "+10 de daño y explosión más grande.", "cost": 40, "mods": {"damage": 10, "blast_radius": 60.0}},
	],
}

const ABILITIES: Dictionary = {
	"Dash": [
		{"name": "Piernas ligeras", "desc": "Se recarga 1 segundo más rápido.", "cost": 15, "mods": {"cooldown": -1.0}},
		{"name": "Impulso largo", "desc": "El dash llega 100 píxeles más lejos.", "cost": 30, "mods": {"dash_distance": 100.0}},
	],
}


## Construye el árbol completo. Raíz -> categorías -> objeto base (nivel 1) -> nivel 2 -> nivel 3.
static func build_tree() -> NaryTree:
	var tree := NaryTree.new(UpgradeData.new("root", "Mejoras"))
	_add_category(tree, "Armas", UpgradeData.Kind.WEAPON, WEAPONS)
	_add_category(tree, "Objetos", UpgradeData.Kind.CONSUMABLE, CONSUMABLES)
	_add_category(tree, "Habilidades", UpgradeData.Kind.ABILITY, ABILITIES)
	return tree


static func _add_category(tree: NaryTree, title: String, kind: UpgradeData.Kind, table: Dictionary) -> void:
	var category: NaryNode = tree.add_node(tree.root, UpgradeData.new("cat_" + title.to_lower(), title, UpgradeData.Kind.CATEGORY))
	for item_key in table:
		# Nivel 1: el objeto base (ya existe en el juego, no cuesta XP).
		var base_id: String = str(item_key).to_lower() + "_1"
		var node: NaryNode = tree.add_node(category, UpgradeData.new(base_id, item_key, kind, item_key, 1, 0, "Versión base."))
		# Niveles 2 y 3: cada uno cuelga del anterior.
		var levels: Array = table[item_key]
		for i in levels.size():
			var info: Dictionary = levels[i]
			var level: int = i + 2
			var data := UpgradeData.new(str(item_key).to_lower() + "_" + str(level), info["name"], kind, item_key, level, info["cost"], info["desc"], info["mods"])
			node = tree.add_node(node, data)
