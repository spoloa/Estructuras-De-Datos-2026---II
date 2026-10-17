extends Node
## Pruebas rápidas de las 4 estructuras.
## Uso: crea una escena con un Node, adjúntale este script y ejecútala (F6).
## La salida aparece en el panel "Output" de Godot.

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_test_stack()
	_test_queue()
	_test_priority_queue()
	_test_dynamic_array()
	print("--- Resultado: %d OK, %d fallos ---" % [_passed, _failed])


func _check(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FALLÓ: " + name)


func _test_stack() -> void:
	var s := Stack.new()
	_check(s.is_empty(), "Stack: nueva está vacía")
	s.push(1)
	s.push(2)
	s.push(3)
	_check(s.peek() == 3, "Stack: peek devuelve el tope")
	_check(s.pop() == 3, "Stack: pop devuelve 3")
	_check(s.pop() == 2, "Stack: pop devuelve 2")
	_check(s.size() == 1, "Stack: size == 1")
	s.pop()
	_check(s.pop() == null, "Stack: pop en vacía devuelve null")


func _test_queue() -> void:
	var q := Queue.new()
	for i in 100:
		q.enqueue(i)
	var en_orden := true
	for i in 60:
		if q.dequeue() != i:
			en_orden = false
	_check(en_orden, "Queue: respeta FIFO (con compactación)")
	_check(q.size() == 40, "Queue: size == 40")
	_check(q.peek() == 60, "Queue: peek == 60")
	q.clear()
	_check(q.is_empty() and q.dequeue() == null, "Queue: clear y vacía")


func _test_priority_queue() -> void:
	var pq := PriorityQueue.new()
	pq.enqueue("baja", 1)
	pq.enqueue("alta", 10)
	pq.enqueue("media", 5)
	pq.enqueue("alta 2", 10)
	_check(pq.dequeue() == "alta", "PQ: sale primero la mayor prioridad")
	_check(pq.dequeue() == "alta 2", "PQ: desempate por orden de llegada")
	_check(pq.dequeue() == "media", "PQ: luego la media")
	_check(pq.dequeue() == "baja", "PQ: al final la baja")
	_check(pq.is_empty(), "PQ: queda vacía")


func _test_dynamic_array() -> void:
	var a := DynamicArray.new()
	for i in 10:
		a.add(i)
	_check(a.size() == 10 and a.capacity() >= 10, "DynArray: crece automáticamente")
	_check(a.get_at(5) == 5, "DynArray: get_at")
	a.insert(0, 99)
	_check(a.get_at(0) == 99 and a.get_at(1) == 0, "DynArray: insert desplaza")
	_check(a.remove_at(0) == 99, "DynArray: remove_at devuelve el eliminado")
	_check(a.index_of(7) == 7 and a.contains(7), "DynArray: index_of / contains")
	for i in 9:
		a.remove_at(0)
	_check(a.size() == 1 and a.capacity() < 16, "DynArray: se reduce al vaciarse")
	_check(a.get_at(50) == null, "DynArray: índice inválido devuelve null")
