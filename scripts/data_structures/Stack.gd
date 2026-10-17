class_name Stack
extends RefCounted
## Pila (LIFO: el último en entrar es el primero en salir).
##
## Uso en el juego: pila de pantallas/estados (menú principal -> juego -> pausa -> opciones)
## y "deshacer" de la última acción.
##
## Complejidad: push, pop, peek, size, is_empty -> O(1).
##
## Ejemplo:
##   var pila := Stack.new()
##   pila.push("juego")
##   pila.push("pausa")
##   pila.pop()   # devuelve "pausa"

var _items: Array = []


## Agrega un elemento en el tope de la pila.
func push(item: Variant) -> void:
	_items.append(item)


## Quita y devuelve el elemento del tope. Devuelve null si la pila está vacía.
func pop() -> Variant:
	if is_empty():
		push_warning("Stack.pop(): la pila está vacía")
		return null
	return _items.pop_back()


## Devuelve el elemento del tope sin quitarlo. Devuelve null si está vacía.
func peek() -> Variant:
	if is_empty():
		return null
	return _items[_items.size() - 1]


## Cantidad de elementos en la pila.
func size() -> int:
	return _items.size()


## true si la pila no tiene elementos.
func is_empty() -> bool:
	return _items.is_empty()


## Elimina todos los elementos.
func clear() -> void:
	_items.clear()


## Copia del contenido, del fondo al tope (útil para depurar o mostrar en el HUD).
func to_array() -> Array:
	return _items.duplicate()
