class_name ComboPopup
extends Node2D
## Texto que sube y se desvanece en el mundo del juego (aquí se usa para avisar "¡COMBO x2!").
##
## Uso:  ComboPopup.spawn(get_tree().current_scene, enemigo.global_position, "+150", Color.GOLD)

## Segundos que dura el texto en pantalla.
const LIFETIME: float = 0.9
## Píxeles que sube.
const RISE: float = 70.0


## Crea un texto flotante en la posición del mundo dada. size = tamaño de la letra.
static func spawn(parent: Node, world_position: Vector2, message: String, color: Color = Color(1.0, 0.85, 0.3), size: int = 26) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var text := ComboPopup.new()
	text.z_index = 100  # por encima de todo
	parent.add_child(text)
	text.global_position = world_position + Vector2(randf_range(-12.0, 12.0), -30.0)
	text._start(message, color, size)


func _start(message: String, color: Color, size: int) -> void:
	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	# Se centra sobre su posición.
	label.position = -label.get_minimum_size() / 2.0

	scale = Vector2(0.6, 0.6)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.45).set_delay(LIFETIME * 0.55)
	tween.chain().tween_callback(queue_free)
