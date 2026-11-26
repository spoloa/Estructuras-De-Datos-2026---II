class_name UpgradeData
extends RefCounted
## Datos de un nodo del árbol de mejoras (es el "value" de cada NaryNode).
##
## Hay dos clases de nodos:
##   - Estructurales (ROOT, CATEGORY): solo organizan el árbol, no se compran.
##   - De mejora (WEAPON, CONSUMABLE, ABILITY): uno por nivel.
##       level 1 = la versión base (la que ya existe en el juego; "se compra" al conseguir el objeto),
##       level 2 y 3 = mejoras que se compran con XP.

## Qué representa el nodo.
enum Kind { ROOT, CATEGORY, WEAPON, CONSUMABLE, ABILITY }

## Identificador único (ej. "pistola_2").
var id: String = ""
## Nombre que se muestra en la interfaz.
var display_name: String = ""
## Texto corto que explica qué hace.
var description: String = ""
## Tipo de nodo.
var kind: Kind = Kind.ROOT
## Nombre del arma / objeto / habilidad a la que pertenece. Es el mismo texto que usa el
## recurso del juego (WeaponData.weapon_name, ConsumableData.display_name o AbilityData.display_name).
var item_key: String = ""
## Nivel de la mejora: 0 = nodo estructural, 1 = base, 2 y 3 = mejoras compradas.
var level: int = 0
## Costo en XP (0 en los nodos que no se compran).
var cost: int = 0
## Cambios que aplica a las estadísticas: {"nombre_de_la_stat": valor_a_sumar}.
## Ej.: {"damage": 1, "fire_rate": 0.5}. Los valores de varios niveles se acumulan.
var mods: Dictionary = {}


func _init(p_id: String = "", p_name: String = "", p_kind: Kind = Kind.ROOT, p_key: String = "", p_level: int = 0, p_cost: int = 0, p_desc: String = "", p_mods: Dictionary = {}) -> void:
	id = p_id
	display_name = p_name
	kind = p_kind
	item_key = p_key
	level = p_level
	cost = p_cost
	description = p_desc
	mods = p_mods


## true si es una mejora real (arma, objeto o habilidad) y no un nodo estructural.
func is_upgrade() -> bool:
	return kind == Kind.WEAPON or kind == Kind.CONSUMABLE or kind == Kind.ABILITY
