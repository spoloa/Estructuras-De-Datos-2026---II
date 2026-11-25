class_name AVLNode
extends RefCounted
## Nodo de un árbol AVL (ver AVLTree.gd).
##
## Cada nodo guarda, además de su dato, la altura y el tamaño de su subárbol.
## Con esos dos números el árbol se mantiene balanceado (altura) y puede responder
## "¿en qué posición quedé?" y "dame el k-ésimo mejor" en O(log n) (tamaño).

## Clave de orden (en el ranking es el puntaje).
var key: int
## Número de llegada: desempata claves iguales y permite repetidos.
var id: int
## Dato que acompaña a la clave (en el ranking: oleadas, tiempo, fecha...).
var value: Variant
## Altura del subárbol que cuelga de este nodo (una hoja vale 1, un hijo vacío vale 0).
var height: int = 1
## Cantidad de nodos del subárbol que cuelga de este nodo (contándose a sí mismo).
var size: int = 1
var left: AVLNode = null
var right: AVLNode = null
## Espacio libre para estructuras que se construyan sobre el AVL
## (por ejemplo, el árbol de intervalos guardará aquí el mayor "fin" de su subárbol).
## Debe ser un dato derivado que _update() de AVLTree pueda recalcular.
var aux: Variant = null


func _init(node_key: int, node_id: int, node_value: Variant = null) -> void:
	key = node_key
	id = node_id
	value = node_value
