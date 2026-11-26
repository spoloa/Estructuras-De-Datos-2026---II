class_name NaryNode
extends RefCounted
## Nodo de un árbol n-ario: guarda un valor, una referencia a su padre y una lista
## de hijos (puede tener 0, 1, 2... n hijos, sin límite).
##
## No se usa directamente: NaryTree crea y conecta los nodos (ver NaryTree.gd).

## Dato que guarda el nodo (en el juego: un UpgradeData).
var value: Variant = null
## Padre del nodo (null si es la raíz).
var parent: NaryNode = null
## Hijos del nodo, en el orden en que se agregaron.
var children: Array[NaryNode] = []


func _init(initial_value: Variant = null) -> void:
	value = initial_value


## true si el nodo no tiene hijos.
func is_leaf() -> bool:
	return children.is_empty()


## Distancia a la raíz: la raíz tiene profundidad 0, sus hijos 1, etc.
func depth() -> int:
	var d: int = 0
	var node: NaryNode = parent
	while node != null:
		d += 1
		node = node.parent
	return d
