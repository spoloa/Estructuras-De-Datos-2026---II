class_name MeleeSwing
extends Node2D
## Efecto visual del golpe del bate: un arco que barre frente al jugador y se desvanece.
## Es solo visual; el daño lo aplica Player._melee_attack().

const SWEEP_TIME: float = 0.10
const FADE_TIME: float = 0.12

var _radius: float = 110.0
var _arc: float = PI * 0.8
## Cuánto del arco se ha barrido (0 a 1).
var _progress: float = 0.0:
	set(value):
		_progress = value
		queue_redraw()
## Opacidad (1 = visible, 0 = invisible).
var _alpha: float = 1.0:
	set(value):
		_alpha = value
		queue_redraw()


## Dibuja el golpe en la dirección aim, con el alcance y el ancho del arma.
func play(aim: Vector2, radius: float, arc_degrees: float) -> void:
	_radius = radius
	_arc = deg_to_rad(arc_degrees)
	rotation = aim.angle()
	var tween := create_tween()
	tween.tween_property(self, "_progress", 1.0, SWEEP_TIME)
	tween.tween_property(self, "_alpha", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var start: float = -_arc / 2.0
	var end: float = start + _arc * _progress
	if _progress <= 0.0:
		return
	# Abanico suave de fondo + borde brillante donde va el bate.
	var points := PackedVector2Array([Vector2.ZERO])
	var steps: int = 18
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(start, end, float(i) / steps)) * _radius)
	draw_colored_polygon(points, Color(1.0, 0.95, 0.8, 0.22 * _alpha))
	draw_arc(Vector2.ZERO, _radius, start, end, 24, Color(1.0, 0.97, 0.85, _alpha), 5.0)
	draw_line(Vector2.ZERO, Vector2.from_angle(end) * _radius, Color(0.6, 0.4, 0.2, _alpha), 7.0)
