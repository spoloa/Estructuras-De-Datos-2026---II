class_name PlayerDeathEffect
extends Node
## Efecto de muerte del personaje principal. Se reproduce una sola vez:
##   1. destello blanco y cámara lenta
##   2. el personaje se pone rojo, se inclina y cae
##   3. estallido de chispas y un "alma" que sube
##   4. la cámara se acerca y los bordes de la pantalla se oscurecen en rojo
##   5. el personaje se desvanece
##
## Uso (lo llama GameFlow cuando el jugador muere):
##     PlayerDeathEffect.play(player)

## Color rojo de la sangre / el tinte de muerte.
const RED: Color = Color(0.85, 0.12, 0.15)

## Sombreado de los bordes de la pantalla (viñeta): transparente al centro, rojo oscuro en las esquinas.
const VIGNETTE_SHADER: String = """
shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float d = distance(UV, vec2(0.5)) * 1.45;
	float v = smoothstep(0.25, 1.0, d) * strength;
	COLOR = vec4(0.35, 0.0, 0.03, v);
}
"""


## Crea y arranca el efecto sobre el jugador.
static func play(player: Node2D) -> void:
	if player == null or not player.is_inside_tree():
		return
	var effect := PlayerDeathEffect.new()
	player.get_tree().current_scene.add_child(effect)
	effect._run(player)


func _run(player: Node2D) -> void:
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	var position: Vector2 = player.global_position

	AudioManager.play("player_death")
	GameFeel.slow_motion(0.3, 0.7)
	GameFeel.burst(position, RED, 34, 420.0, 7.0)
	GameFeel.rise(position + Vector2(0, -20), Color(1.0, 0.95, 0.9), 18)

	_make_vignette()
	if camera != null:
		var zoom_tween := _real_time_tween()
		zoom_tween.tween_property(camera, "zoom", camera.zoom * 1.3, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if sprite != null:
		_animate_sprite(sprite)


## El personaje: destello, tinte rojo, cae de lado y se desvanece.
func _animate_sprite(sprite: AnimatedSprite2D) -> void:
	sprite.pause()
	if sprite.has_meta("flash_tween"):  # el destello de "me golpearon" no debe pelear con esta animación
		var old: Variant = sprite.get_meta("flash_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var fall_side: float = 1.0 if sprite.flip_h else -1.0  # cae hacia atrás, según hacia dónde mirara
	sprite.set_meta("rest_modulate", Color(1, 1, 1))
	sprite.modulate = Color(4, 4, 4, 1)  # destello blanco
	var tween := _real_time_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.25)
	tween.tween_property(sprite, "rotation", deg_to_rad(80.0) * fall_side, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 14.0, 0.5)
	tween.tween_interval(0.35)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.7)


## Bordes rojos oscuros que aparecen poco a poco (por encima del juego y el HUD, debajo de los menús).
func _make_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	material.shader = shader
	rect.material = material
	layer.add_child(rect)
	var tween := _real_time_tween()
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("strength", value), 0.0, 0.9, 1.2)


## Tween que no se frena con la cámara lenta (así dura lo mismo en segundos reales).
func _real_time_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	return tween
