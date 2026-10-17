class_name DynamicArray
extends RefCounted
## Arreglo dinámico: arreglo que crece (y se reduce) automáticamente.
##
## Uso en el juego: inventario del jugador (cantidad de ítems variable).
##
## Implementación: guarda los datos en un arreglo interno de capacidad fija (_data) y
## lleva la cuenta de cuántos espacios están realmente usados (_size).
## Cuando se llena, la capacidad se DUPLICA; cuando queda al 25% se REDUCE a la mitad.
##
## Complejidad: get_at, set_at -> O(1); add -> O(1) amortizado;
##              insert, remove_at, index_of -> O(n).
##
## Ejemplo:
##   var inv := DynamicArray.new()
##   inv.add("espada")
##   inv.add("poción")
##   inv.get_at(1)   # devuelve "poción"

const INITIAL_CAPACITY: int = 4

var _data: Array = []
var _size: int = 0


func _init(initial_capacity: int = INITIAL_CAPACITY) -> void:
	_data.resize(maxi(1, initial_capacity))


## Agrega un elemento al final.
func add(item: Variant) -> void:
	if _size == _data.size():
		_data.resize(_data.size() * 2)
	_data[_size] = item
	_size += 1


## Inserta un elemento en la posición index (0..size), desplazando los demás a la derecha.
## Devuelve false si el índice es inválido.
func insert(index: int, item: Variant) -> bool:
	if index < 0 or index > _size:
		push_error("DynamicArray.insert(): índice fuera de rango (%d)" % index)
		return false
	if _size == _data.size():
		_data.resize(_data.size() * 2)
	for i in range(_size, index, -1):
		_data[i] = _data[i - 1]
	_data[index] = item
	_size += 1
	return true


## Devuelve el elemento en index. Devuelve null si el índice es inválido.
func get_at(index: int) -> Variant:
	if not _is_valid_index(index):
		push_error("DynamicArray.get_at(): índice fuera de rango (%d)" % index)
		return null
	return _data[index]


## Reemplaza el elemento en index. Devuelve false si el índice es inválido.
func set_at(index: int, item: Variant) -> bool:
	if not _is_valid_index(index):
		push_error("DynamicArray.set_at(): índice fuera de rango (%d)" % index)
		return false
	_data[index] = item
	return true


## Elimina y devuelve el elemento en index, desplazando los demás a la izquierda.
## Devuelve null si el índice es inválido.
func remove_at(index: int) -> Variant:
	if not _is_valid_index(index):
		push_error("DynamicArray.remove_at(): índice fuera de rango (%d)" % index)
		return null
	var removed: Variant = _data[index]
	for i in range(index, _size - 1):
		_data[i] = _data[i + 1]
	_data[_size - 1] = null
	_size -= 1
	_shrink_if_needed()
	return removed


## Posición de la primera aparición de item, o -1 si no está.
func index_of(item: Variant) -> int:
	for i in _size:
		if _data[i] == item:
			return i
	return -1


## true si el item está en el arreglo.
func contains(item: Variant) -> bool:
	return index_of(item) != -1


## Cantidad de elementos guardados.
func size() -> int:
	return _size


## Espacios reservados actualmente (>= size).
func capacity() -> int:
	return _data.size()


## true si no hay elementos.
func is_empty() -> bool:
	return _size == 0


## Elimina todos los elementos y vuelve a la capacidad inicial.
func clear() -> void:
	_data.clear()
	_data.resize(INITIAL_CAPACITY)
	_size = 0


## Copia de los elementos guardados (sin los espacios vacíos).
func to_array() -> Array:
	return _data.slice(0, _size)


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _size


## Reduce la capacidad a la mitad cuando solo se usa el 25% o menos.
func _shrink_if_needed() -> void:
	var cap: int = _data.size()
	if cap > INITIAL_CAPACITY and _size <= cap / 4:
		_data.resize(cap / 2)
