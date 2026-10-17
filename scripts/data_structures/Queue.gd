class_name Queue
extends RefCounted
## Cola (FIFO: el primero en entrar es el primero en salir).
##
## Uso en el juego: cola de oleadas de enemigos; cada oleada se encola y sale en orden.
##
## Implementación: arreglo con un índice de cabeza (_head). Así dequeue() es O(1)
## amortizado, en lugar de O(n) que costaría Array.pop_front() al desplazar todo.
## Cuando más de la mitad del arreglo son espacios ya consumidos, se compacta.
##
## Complejidad: enqueue, dequeue, peek, size, is_empty -> O(1) amortizado.
##
## Ejemplo:
##   var cola := Queue.new()
##   cola.enqueue("oleada 1")
##   cola.enqueue("oleada 2")
##   cola.dequeue()   # devuelve "oleada 1"

const COMPACT_THRESHOLD: int = 32

var _items: Array = []
var _head: int = 0


## Agrega un elemento al final de la cola.
func enqueue(item: Variant) -> void:
	_items.append(item)


## Quita y devuelve el elemento del frente. Devuelve null si la cola está vacía.
func dequeue() -> Variant:
	if is_empty():
		push_warning("Queue.dequeue(): la cola está vacía")
		return null
	var item: Variant = _items[_head]
	_items[_head] = null  # libera la referencia
	_head += 1
	_compact_if_needed()
	return item


## Devuelve el elemento del frente sin quitarlo. Devuelve null si está vacía.
func peek() -> Variant:
	if is_empty():
		return null
	return _items[_head]


## Cantidad de elementos en la cola.
func size() -> int:
	return _items.size() - _head


## true si la cola no tiene elementos.
func is_empty() -> bool:
	return size() == 0


## Elimina todos los elementos.
func clear() -> void:
	_items.clear()
	_head = 0


## Copia del contenido, del frente al final.
func to_array() -> Array:
	return _items.slice(_head)


## Elimina el espacio ya consumido cuando es más de la mitad del arreglo.
func _compact_if_needed() -> void:
	if _head >= COMPACT_THRESHOLD and _head * 2 >= _items.size():
		_items = _items.slice(_head)
		_head = 0
