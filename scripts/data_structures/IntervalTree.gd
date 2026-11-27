class_name IntervalTree
extends RefCounted
## Árbol de intervalos (AVL aumentado) para eventos temporales.
## Responde en O(log n + k): query_point(t) y query_overlap(a, b).

class IntervalNode: # <--- CAMBIADO AQUÍ
	var start: float
	var end: float
	var event_id: String
	var data: Dictionary
	var max_end: float
	var height: int
	var left: IntervalNode # <--- CAMBIADO AQUÍ
	var right: IntervalNode # <--- CAMBIADO AQUÍ

	func _init(p_start: float, p_end: float, p_id: String, p_data: Dictionary) -> void:
		start = p_start
		end = p_end
		event_id = p_id
		data = p_data
		max_end = p_end
		height = 1

var root: IntervalNode = null # <--- CAMBIADO AQUÍ
var size: int = 0

func _h(n: IntervalNode) -> int: # <--- CAMBIADO AQUÍ
	return n.height if n else 0

func _max_end(n: IntervalNode) -> float: # <--- CAMBIADO AQUÍ
	return n.max_end if n else -INF

func _update(n: IntervalNode) -> void: # <--- CAMBIADO AQUÍ
	n.height = 1 + maxi(_h(n.left), _h(n.right))
	n.max_end = maxf(n.end, maxf(_max_end(n.left), _max_end(n.right)))

func _bf(n: IntervalNode) -> int: # <--- CAMBIADO AQUÍ
	return _h(n.left) - _h(n.right) if n else 0

func _rotate_right(y: IntervalNode) -> IntervalNode: # <--- CAMBIADO AQUÍ
	var x: IntervalNode = y.left # <--- CAMBIADO AQUÍ
	y.left = x.right
	x.right = y
	_update(y)
	_update(x)
	return x

func _rotate_left(x: IntervalNode) -> IntervalNode: # <--- CAMBIADO AQUÍ
	var y: IntervalNode = x.right # <--- CAMBIADO AQUÍ
	x.right = y.left
	y.left = x
	_update(x)
	_update(y)
	return y

func _rebalance(n: IntervalNode) -> IntervalNode: # <--- CAMBIADO AQUÍ
	_update(n)
	var b: int = _bf(n)
	if b > 1 and _bf(n.left) >= 0:
		return _rotate_right(n)
	if b > 1 and _bf(n.left) < 0:
		n.left = _rotate_left(n.left)
		return _rotate_right(n)
	if b < -1 and _bf(n.right) <= 0:
		return _rotate_left(n)
	if b < -1 and _bf(n.right) > 0:
		n.right = _rotate_right(n.right)
		return _rotate_left(n)
	return n

func insert(start: float, end: float, event_id: String, data: Dictionary = {}) -> void:
	if end < start:
		push_error("IntervalTree.insert: end < start")
		return
	root = _insert(root, start, end, event_id, data)
	size += 1

func _insert(n: IntervalNode, start: float, end: float, event_id: String, data: Dictionary) -> IntervalNode: # <--- CAMBIADO AQUÍ
	if n == null:
		return IntervalNode.new(start, end, event_id, data) # <--- CAMBIADO AQUÍ
	if start < n.start:
		n.left = _insert(n.left, start, end, event_id, data)
	else:
		n.right = _insert(n.right, start, end, event_id, data)
	return _rebalance(n)

func remove(event_id: String) -> bool:
	var removed := false
	root = _remove(root, event_id, removed)
	if removed:
		size -= 1
	return removed

func _remove(n: IntervalNode, event_id: String, removed: bool) -> IntervalNode: # <--- CAMBIADO AQUÍ
	if n == null:
		return null
	if n.event_id == event_id:
		removed = true
		if n.left == null:
			return n.right
		if n.right == null:
			return n.left
		var succ: IntervalNode = _min_node(n.right) # <--- CAMBIADO AQUÍ
		n.start = succ.start
		n.end = succ.end
		n.event_id = succ.event_id
		n.data = succ.data
		n.right = _remove(n.right, succ.event_id, false)
		return _rebalance(n)
	n.left = _remove(n.left, event_id, removed)
	if removed:
		return _rebalance(n)
	n.right = _remove(n.right, event_id, removed)
	return _rebalance(n)

func _min_node(n: IntervalNode) -> IntervalNode: # <--- CAMBIADO AQUÍ
	while n.left:
		n = n.left
	return n

func query_point(t: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_query_point(root, t, out)
	return out

func _query_point(n: IntervalNode, t: float, out: Array[Dictionary]) -> void: # <--- CAMBIADO AQUÍ
	if n == null:
		return
	if n.left and n.left.max_end >= t:
		_query_point(n.left, t, out)
	if n.start <= t and t <= n.end:
		out.append({"id": n.event_id, "start": n.start, "end": n.end, "data": n.data})
	if n.right and n.start <= t and n.right.max_end >= t:
		_query_point(n.right, t, out)

func query_overlap(a: float, b: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_query_overlap(root, a, b, out)
	return out

func _query_overlap(n: IntervalNode, a: float, b: float, out: Array[Dictionary]) -> void: # <--- CAMBIADO AQUÍ
	if n == null:
		return
	if n.left and n.left.max_end >= a:
		_query_overlap(n.left, a, b, out)
	if n.start <= b and n.end >= a:
		out.append({"id": n.event_id, "start": n.start, "end": n.end, "data": n.data})
	if n.right and n.start <= b and n.right.max_end >= a:
		_query_overlap(n.right, a, b, out)

func is_empty() -> bool:
	return root == null

func clear() -> void:
	root = null
	size = 0
