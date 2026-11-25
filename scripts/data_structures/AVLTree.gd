class_name AVLTree
extends RefCounted
## Árbol AVL: árbol binario de búsqueda que se mantiene balanceado con rotaciones.
##
## Uso en el juego: ranking de partidas (ver ScoreManager.gd). La clave es el puntaje.
##
## Por qué un AVL y no un árbol binario de búsqueda simple: si los puntajes llegan ya
## ordenados (el jugador mejora partida tras partida) un BST simple se vuelve una lista
## y cada operación cuesta O(n). El AVL garantiza que la diferencia de altura entre los
## dos hijos de cualquier nodo sea como máximo 1, así que su altura siempre es O(log n).
##
## Orden: mayor clave = mejor posición. Si dos entradas tienen la misma clave, la que
## entró primero (menor "id") queda mejor. Por eso se permiten claves repetidas.
##
## Gracias al tamaño de cada subárbol, además de insertar y buscar se puede responder:
##   - rank(clave, id): ¿en qué posición quedó esta entrada? (1 = la mejor)
##   - select(k):       ¿qué entrada ocupa la posición k?
##
## Complejidad (n = cantidad de entradas, k = cantidad pedida):
##   insert, remove, find, rank, select -> O(log n) en el peor caso
##   get_top(k)                         -> O(log n + k)
##   to_array_preorder()                -> O(n)
##
## Ejemplo:
##   var arbol := AVLTree.new()
##   var id_a := arbol.insert(1200, {"oleadas": 3})
##   arbol.insert(800)
##   arbol.rank(1200, id_a)   # 1 (es el mejor)
##   arbol.select(2)          # {"key": 800, "id": 1, "value": null}
##   arbol.get_top(1)         # [{"key": 1200, ...}]
##
## Para construir otra estructura sobre este árbol (por ejemplo un árbol de intervalos)
## basta con heredar de AVLTree y sobrescribir _update(), que se llama después de cada
## cambio y después de cada rotación.

var _root: AVLNode = null
var _next_id: int = 0


## Inserta una entrada y devuelve su id (sirve luego para pedir su posición con rank).
## Si se pasa un id (>= 0) se usa ese en vez de uno nuevo: es lo que hace el ranking
## al cargarse desde el disco, para conservar el orden de llegada de los empates.
## Devuelve -1 si ya existe una entrada con esa clave y ese id.
func insert(key: int, value: Variant = null, id: int = -1) -> int:
	if id < 0:
		id = _next_id
	if _find_node(key, id) != null:
		push_warning("AVLTree.insert(): ya existe la entrada (%d, %d)" % [key, id])
		return -1
	_next_id = maxi(_next_id, id + 1)
	_root = _insert(_root, AVLNode.new(key, id, value))
	return id


## Elimina la entrada con esa clave e id. Devuelve false si no existe.
func remove(key: int, id: int) -> bool:
	if _find_node(key, id) == null:
		return false
	_root = _remove(_root, key, id)
	return true


## Busca una entrada. Devuelve {"key", "id", "value"} o null si no existe.
func find(key: int, id: int) -> Variant:
	var node: AVLNode = _find_node(key, id)
	if node == null:
		return null
	return _entry(node)


## Posición de una entrada en el ranking (1 = la mejor). Devuelve -1 si no existe.
## Cuenta cuántas entradas son mejores bajando por el árbol: cada vez que se va a la
## izquierda, el nodo actual y todo su subárbol derecho son mejores.
func rank(key: int, id: int) -> int:
	var better: int = 0
	var node: AVLNode = _root
	while node != null:
		var c: int = _compare(key, id, node.key, node.id)
		if c < 0:
			better += 1 + _size(node.right)
			node = node.left
		elif c > 0:
			node = node.right
		else:
			return better + _size(node.right) + 1
	return -1


## Entrada que ocupa la posición k del ranking (1 = la mejor).
## Devuelve {"key", "id", "value"} o null si k está fuera de rango.
func select(k: int) -> Variant:
	if k < 1 or k > size():
		return null
	var node: AVLNode = _root
	while node != null:
		var right_size: int = _size(node.right)
		if k <= right_size:
			node = node.right
		elif k == right_size + 1:
			return _entry(node)
		else:
			k -= right_size + 1
			node = node.left
	return null


## Las `count` mejores entradas, de mayor a menor. Es un recorrido inorden inverso
## (derecha, nodo, izquierda) que se detiene al llegar a `count`; usa la pila propia
## (Stack.gd) en vez de recursión.
func get_top(count: int) -> Array:
	var result: Array = []
	var stack: Stack = Stack.new()
	var node: AVLNode = _root
	while (node != null or not stack.is_empty()) and result.size() < count:
		while node != null:
			stack.push(node)
			node = node.right
		node = stack.pop()
		result.append(_entry(node))
		node = node.left
	return result


## Todas las entradas en recorrido preorden (nodo, izquierda, derecha).
## Es el orden que se usa para guardar el ranking. Al cargarlo se vuelven a insertar las
## entradas con su id original: las posiciones del ranking quedan idénticas (la clave y el
## id fijan el orden). La forma exacta del árbol puede cambiar, pero eso no importa: el AVL
## siempre queda balanceado. Cargar n entradas cuesta O(n log n).
func to_array_preorder() -> Array:
	var result: Array = []
	if _root == null:
		return result
	var stack: Stack = Stack.new()
	stack.push(_root)
	while not stack.is_empty():
		var node: AVLNode = stack.pop()
		result.append(_entry(node))
		if node.right != null:
			stack.push(node.right)  # se apila primero la derecha para sacar antes la izquierda
		if node.left != null:
			stack.push(node.left)
	return result


## Cantidad de entradas.
func size() -> int:
	return _size(_root)


## Altura del árbol (0 si está vacío).
func height() -> int:
	return _height(_root)


## true si no hay entradas.
func is_empty() -> bool:
	return _root == null


## Elimina todas las entradas y reinicia el contador de ids.
func clear() -> void:
	_root = null
	_next_id = 0


## Comprueba que el árbol cumple sus reglas: orden de búsqueda, alturas y tamaños
## bien calculados y balance (diferencia de alturas <= 1) en todos los nodos.
## Sirve para las pruebas automáticas; recorre todo el árbol, O(n).
func validate() -> bool:
	return _validate(_root, null, null)


# ---------------------------------------------------------------------------
# Internos
# ---------------------------------------------------------------------------

## Compara dos entradas. Devuelve -1 si la primera es PEOR que la segunda,
## 1 si es MEJOR y 0 si son la misma. Mayor clave = mejor; si empatan, gana la que
## llegó antes (id menor).
func _compare(key_a: int, id_a: int, key_b: int, id_b: int) -> int:
	if key_a != key_b:
		return -1 if key_a < key_b else 1
	if id_a != id_b:
		return -1 if id_a > id_b else 1
	return 0


func _entry(node: AVLNode) -> Dictionary:
	return {"key": node.key, "id": node.id, "value": node.value}


func _height(node: AVLNode) -> int:
	return 0 if node == null else node.height


func _size(node: AVLNode) -> int:
	return 0 if node == null else node.size


func _find_node(key: int, id: int) -> AVLNode:
	var node: AVLNode = _root
	while node != null:
		var c: int = _compare(key, id, node.key, node.id)
		if c == 0:
			return node
		node = node.left if c < 0 else node.right
	return null


## Recalcula los datos derivados de un nodo a partir de sus hijos.
## Se llama siempre de abajo hacia arriba (primero el hijo, luego el padre).
## Las estructuras que hereden de AVLTree pueden sobrescribirlo (llamando a super)
## para mantener datos extra en AVLNode.aux.
func _update(node: AVLNode) -> void:
	node.height = 1 + maxi(_height(node.left), _height(node.right))
	node.size = 1 + _size(node.left) + _size(node.right)


## Rotación a la derecha: el hijo izquierdo pasa a ser la nueva raíz del subárbol.
##
##        y                x
##       / \              / \
##      x   C    ->      A   y
##     / \                  / \
##    A   B                B   C
func _rotate_right(y: AVLNode) -> AVLNode:
	var x: AVLNode = y.left
	y.left = x.right
	x.right = y
	_update(y)  # y quedó debajo de x, por eso se actualiza primero
	_update(x)
	return x


## Rotación a la izquierda: el hijo derecho pasa a ser la nueva raíz del subárbol.
## Es la imagen en espejo de _rotate_right.
func _rotate_left(x: AVLNode) -> AVLNode:
	var y: AVLNode = x.right
	x.right = y.left
	y.left = x
	_update(x)
	_update(y)
	return y


## Actualiza el nodo y, si quedó desbalanceado, lo arregla con una de las cuatro
## rotaciones. Devuelve la nueva raíz del subárbol.
func _rebalance(node: AVLNode) -> AVLNode:
	_update(node)
	var balance: int = _height(node.left) - _height(node.right)
	if balance > 1:  # pesa demasiado la izquierda
		if _height(node.left.left) < _height(node.left.right):
			node.left = _rotate_left(node.left)  # caso izquierda-derecha: primero se endereza
		return _rotate_right(node)  # caso izquierda-izquierda
	if balance < -1:  # pesa demasiado la derecha
		if _height(node.right.right) < _height(node.right.left):
			node.right = _rotate_right(node.right)  # caso derecha-izquierda: primero se endereza
		return _rotate_left(node)  # caso derecha-derecha
	return node


func _insert(node: AVLNode, new_node: AVLNode) -> AVLNode:
	if node == null:
		return new_node
	if _compare(new_node.key, new_node.id, node.key, node.id) < 0:
		node.left = _insert(node.left, new_node)
	else:
		node.right = _insert(node.right, new_node)
	return _rebalance(node)


func _remove(node: AVLNode, key: int, id: int) -> AVLNode:
	if node == null:
		return null
	var c: int = _compare(key, id, node.key, node.id)
	if c < 0:
		node.left = _remove(node.left, key, id)
	elif c > 0:
		node.right = _remove(node.right, key, id)
	else:
		# Encontrado. Con 0 o 1 hijo, el hijo (o nada) ocupa su lugar.
		if node.left == null:
			return node.right
		if node.right == null:
			return node.left
		# Con 2 hijos lo reemplaza su sucesor: el menor nodo del subárbol derecho.
		var successor: AVLNode = _min_node(node.right)
		successor.right = _remove_min(node.right)
		successor.left = node.left
		return _rebalance(successor)
	return _rebalance(node)


func _min_node(node: AVLNode) -> AVLNode:
	while node.left != null:
		node = node.left
	return node


## Quita el menor nodo del subárbol y devuelve el subárbol resultante, ya balanceado.
func _remove_min(node: AVLNode) -> AVLNode:
	if node.left == null:
		return node.right
	node.left = _remove_min(node.left)
	return _rebalance(node)


## low y high son los límites que impone el orden de búsqueda (null = sin límite).
func _validate(node: AVLNode, low: AVLNode, high: AVLNode) -> bool:
	if node == null:
		return true
	if low != null and _compare(node.key, node.id, low.key, low.id) <= 0:
		return false
	if high != null and _compare(node.key, node.id, high.key, high.id) >= 0:
		return false
	var left_height: int = _height(node.left)
	var right_height: int = _height(node.right)
	if node.height != 1 + maxi(left_height, right_height):
		return false
	if node.size != 1 + _size(node.left) + _size(node.right):
		return false
	if absi(left_height - right_height) > 1:
		return false
	return _validate(node.left, low, node) and _validate(node.right, node, high)
