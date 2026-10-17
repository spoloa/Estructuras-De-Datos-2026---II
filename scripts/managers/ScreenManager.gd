extends Node
## Gestor de pantallas basado en una PILA (Stack).
##
## Cada menú que se abre se apila encima del anterior (juego -> pausa -> opciones).
## Al cerrar el menú de arriba (pop) se vuelve automáticamente al anterior.
## Cuando la pila queda vacía, el juego se reanuda.
##
## Se registra como Autoload con el nombre "ScreenManager" (Proyecto > Configuración
## del proyecto > Globales), por eso este script NO declara class_name.

## Si es false, la tecla Esc no abre el menú de pausa (útil en el menú principal o game over).
var pause_enabled: bool = true

var _stack: Stack = Stack.new()
var _layer: CanvasLayer


func _ready() -> void:
	# Debe seguir funcionando mientras el juego está en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100  # siempre por encima del HUD
	add_child(_layer)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _stack.is_empty():
		if pause_enabled:
			push_screen(PauseMenu.new())
	else:
		pop_screen()  # Esc siempre "vuelve atrás" un nivel
	get_viewport().set_input_as_handled()


## Apila una pantalla encima de la actual y pausa el juego.
func push_screen(screen: Control) -> void:
	var current: Control = _stack.peek()
	if current != null:
		current.hide()  # la pantalla de abajo se oculta, no se destruye
	_layer.add_child(screen)
	_stack.push(screen)
	get_tree().paused = true
	print("Pantallas en la pila: ", _stack.size())


## Quita la pantalla de arriba. Si no queda ninguna, reanuda el juego.
func pop_screen() -> void:
	if _stack.is_empty():
		return
	var top: Control = _stack.pop()
	top.queue_free()
	var below: Control = _stack.peek()
	if below != null:
		below.show()
	else:
		get_tree().paused = false
	print("Pantallas en la pila: ", _stack.size())


## true si no hay ningún menú abierto.
func is_empty() -> bool:
	return _stack.is_empty()
