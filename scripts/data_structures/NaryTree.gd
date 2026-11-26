class_name NaryTree
extends RefCounted
## Árbol n-ario: cada nodo puede tener cualquier cantidad de hijos.
##
## Uso en el juego: árbol de mejoras (ver UpgradeCatalog.gd y UpgradeManager.gd).
##
## Por qué un árbol n-ario: las mejoras tienen dependencias. Una mejora de nivel 2 solo
## se puede comprar si ya se tiene la de nivel 1 (su padre), y la de nivel 3 solo si ya
## se tiene la de nivel 2. Además, cada arma / objeto / habilidad es una rama distinta
## y todas cuelgan de una categoría (Armas, Objetos, Habilidades). Esa relación
## "para llegar a un nodo hay que pasar por su padre" es justo la de un árbol, y como
## un padre puede tener muchos hijos (la categoría Armas tiene 4 armas) no basta
## con un árbol binario.
##
## Estructura del juego:
##   Raíz
##   ├── Armas ──── Pistola ── Nivel 2 ── Nivel 3
##   │         └─── Escopeta ─ Nivel 2 ── Nivel 3 ...
##   ├── Objetos ── Corazón ... / Bomba ...
##   └── Habilidades ── Dash ...
##
## Los recorridos se hacen con una PILA propia (Stack.gd) en vez de recursión, así el
## árbol no depende del límite de recursión del lenguaje.
##
## Complejidad (n = cantidad de nodos):
##   add_node            -> O(1)
##   size, height, find, preorder, find_all -> O(n)
##   path_to_root(node)  -> O(h), con h = altura del nodo
##
## Ejemplo:
##   var arbol := NaryTree.new("raíz")
##   var armas := arbol.add_node(arbol.root, "Armas")
##   var pistola := arbol.add_node(armas, "Pistola")
##   arbol.add_node(pistola, "Pistola nivel 2")
##   arbol.size()      # 4
##   arbol.height()    # 3
##   arbol.preorder()  # [raíz, Armas, Pistola, Pistola nivel 2] (los nodos, no los textos)

## Raíz del árbol (siempre existe).
var root: NaryNode


func _init(root_value: Variant = null) -> void:
	root = NaryNode.new(root_value)


## Agrega un hijo con ese valor al final de la lista de hijos de parent y lo devuelve.
## Devuelve null si parent es null.
func add_node(parent: NaryNode, value: Variant) -> NaryNode:
	if parent == null:
		push_warning("NaryTree.add_node(): el padre no puede ser null")
		return null
	var node := NaryNode.new(value)
	node.parent = parent
	parent.children.append(node)
	return node


## Cantidad total de nodos (incluida la raíz).
func size() -> int:
	return preorder().size()


## Altura del árbol: cantidad de niveles. Solo la raíz = 1.
func height() -> int:
	var best: int = 0
	for node in preorder():
		best = maxi(best, (node as NaryNode).depth() + 1)
	return best


## Todos los nodos en preorden (primero el padre y luego cada hijo, de izquierda a derecha).
## Se recorre con una pila: se saca un nodo, se anota, y se apilan sus hijos al revés
## para que el primer hijo sea el primero en salir.
func preorder(start: NaryNode = null) -> Array[NaryNode]:
	var result: Array[NaryNode] = []
	var begin: NaryNode = start if start != null else root
	var pending := Stack.new()
	pending.push(begin)
	while not pending.is_empty():
		var node: NaryNode = pending.pop()
		result.append(node)
		for i in range(node.children.size() - 1, -1, -1):
			pending.push(node.children[i])
	return result


## Primer nodo (en preorden) para el que predicate(node) devuelve true; null si no hay.
func find(predicate: Callable) -> NaryNode:
	for node in preorder():
		if predicate.call(node):
			return node
	return null


## Todos los nodos (en preorden) para los que predicate(node) devuelve true.
func find_all(predicate: Callable) -> Array[NaryNode]:
	var result: Array[NaryNode] = []
	for node in preorder():
		if predicate.call(node):
			result.append(node)
	return result


## Camino desde la raíz hasta node (ambos incluidos). Vacío si node es null.
func path_to_root(node: NaryNode) -> Array[NaryNode]:
	var path: Array[NaryNode] = []
	var current: NaryNode = node
	while current != null:
		path.push_front(current)
		current = current.parent
	return path
