class_name PriorityQueue
extends RefCounted
## Cola con prioridad implementada con un montículo binario (heap).
##
## Uso en el juego: objetivos/eventos de los enemigos. Sale primero el elemento con
## MAYOR prioridad (ej.: jugador cerca = 10, aliado débil = 5, decoración = 1).
## Si dos elementos tienen la misma prioridad, sale primero el que entró antes (estable).
##
## Implementación: arreglo que representa un árbol binario completo.
##   padre de i = (i - 1) / 2 ; hijos de i = 2i + 1 y 2i + 2
##
## Complejidad: enqueue y dequeue -> O(log n); peek, size, is_empty -> O(1).
##
## Ejemplo:
##   var pq := PriorityQueue.new()
##   pq.enqueue("atacar decoración", 1)
##   pq.enqueue("atacar jugador", 10)
##   pq.dequeue()   # devuelve "atacar jugador"

var _heap: Array = []   # cada nodo: {"item": Variant, "priority": int, "order": int}
var _counter: int = 0   # contador de inserción para desempatar


## Inserta un elemento con su prioridad (mayor número = más prioritario).
func enqueue(item: Variant, priority: int) -> void:
	_heap.append({"item": item, "priority": priority, "order": _counter})
	_counter += 1
	_sift_up(_heap.size() - 1)


## Quita y devuelve el elemento más prioritario. Devuelve null si está vacía.
func dequeue() -> Variant:
	if is_empty():
		push_warning("PriorityQueue.dequeue(): la cola está vacía")
		return null
	var top: Dictionary = _heap[0]
	var last: Dictionary = _heap.pop_back()
	if not _heap.is_empty():
		_heap[0] = last
		_sift_down(0)
	return top["item"]


## Devuelve el elemento más prioritario sin quitarlo. Devuelve null si está vacía.
func peek() -> Variant:
	if is_empty():
		return null
	return _heap[0]["item"]


## Prioridad del elemento que saldría primero (null si está vacía).
func peek_priority() -> Variant:
	if is_empty():
		return null
	return _heap[0]["priority"]


## Cantidad de elementos.
func size() -> int:
	return _heap.size()


## true si no hay elementos.
func is_empty() -> bool:
	return _heap.is_empty()


## Elimina todos los elementos.
func clear() -> void:
	_heap.clear()
	_counter = 0


## true si el nodo a debe salir antes que el nodo b.
func _has_higher_priority(a: Dictionary, b: Dictionary) -> bool:
	if a["priority"] != b["priority"]:
		return a["priority"] > b["priority"]
	return a["order"] < b["order"]


## Sube el nodo en el índice i hasta restaurar la propiedad del montículo.
func _sift_up(i: int) -> void:
	while i > 0:
		var parent: int = (i - 1) / 2
		if _has_higher_priority(_heap[i], _heap[parent]):
			_swap(i, parent)
			i = parent
		else:
			break


## Baja el nodo en el índice i hasta restaurar la propiedad del montículo.
func _sift_down(i: int) -> void:
	var n: int = _heap.size()
	while true:
		var left: int = 2 * i + 1
		var right: int = 2 * i + 2
		var best: int = i
		if left < n and _has_higher_priority(_heap[left], _heap[best]):
			best = left
		if right < n and _has_higher_priority(_heap[right], _heap[best]):
			best = right
		if best == i:
			break
		_swap(i, best)
		i = best


func _swap(i: int, j: int) -> void:
	var tmp: Dictionary = _heap[i]
	_heap[i] = _heap[j]
	_heap[j] = tmp
