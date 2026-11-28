extends Node
## Efectos de "sensación de juego": pausa breve al golpear (hit-stop), temblor de cámara,
## destello al recibir daño y chispas al morir un enemigo.
##
## Se registra como Autoload con el nombre "GameFeel", por eso NO declara class_name.
## Todos los efectos son cortos y no cambian la lógica del juego.

## Si es false, se desactivan el temblor y la pausa al golpear (opción de accesibilidad).
var effects_enabled: bool = true

var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _stop_id: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		return
	_shake_time_left -= delta
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	if _shake_time_left <= 0.0:
		camera.offset = Vector2.ZERO
		return
	var power: float = _shake_strength * (_shake_time_left / _shake_duration)
	camera.offset = Vector2(randf_range(-power, power), randf_range(-power, power))


## Deja la cámara y la velocidad del juego como estaban (se llama al empezar una partida).
func reset() -> void:
	_stop_id += 1
	Engine.time_scale = 1.0
	_shake_time_left = 0.0
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		camera.offset = Vector2.ZERO


## Congela el juego casi por completo durante "duration" segundos reales (da peso a los golpes).
func hit_stop(duration: float) -> void:
	if not effects_enabled:
		return
	_stop_id += 1
	var my_id: int = _stop_id
	Engine.time_scale = 0.05
	# Temporizador que ignora la velocidad del juego (si no, nunca terminaría).
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_id == _stop_id:  # si empezó otra pausa mientras tanto, esa se encarga de restaurar
		Engine.time_scale = 1.0


## Cámara lenta: el juego va a "speed" (0.3 = al 30 %) durante "duration" segundos reales.
func slow_motion(speed: float, duration: float) -> void:
	if not effects_enabled:
		return
	_stop_id += 1
	var my_id: int = _stop_id
	Engine.time_scale = speed
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_id == _stop_id:
		Engine.time_scale = 1.0


## Sacude la cámara: strength = píxeles de desplazamiento máximo, duration = segundos.
func shake(strength: float, duration: float) -> void:
	if not effects_enabled:
		return
	if strength * duration > _shake_strength * maxf(_shake_time_left, 0.0):  # un temblor más fuerte reemplaza al débil
		_shake_strength = strength
		_shake_duration = duration
		_shake_time_left = duration


## Destello breve de un sprite (por defecto blanco: "me golpearon").
func flash(item: CanvasItem, color: Color = Color(3.0, 3.0, 3.0), time: float = 0.12) -> void:
	if item == null or not is_instance_valid(item):
		return
	# El color "normal" del sprite (blanco, o el tinte propio como el del jefe, guardado en el meta "rest_modulate").
	var rest: Color = item.get_meta("rest_modulate", Color(1, 1, 1))
	rest.a = item.modulate.a
	item.modulate = Color(color.r, color.g, color.b, item.modulate.a)
	if item.has_meta("flash_tween"):
		var old: Variant = item.get_meta("flash_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var tween: Tween = item.create_tween()
	tween.tween_property(item, "modulate", rest, time)
	item.set_meta("flash_tween", tween)


## Chispas que salen disparadas desde un punto del mundo.
func burst(world_position: Vector2, color: Color, amount: int = 14, speed: float = 220.0, size: float = 5.0) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.55
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.damping_min = 120.0
	particles.damping_max = 220.0
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size
	particles.color = color
	particles.z_index = 50
	scene.add_child(particles)
	particles.global_position = world_position
	particles.emitting = true
	get_tree().create_timer(particles.lifetime + 0.2).timeout.connect(particles.queue_free)


## Partículas que suben lentamente desde un punto (como un alma que se va).
func rise(world_position: Vector2, color: Color, amount: int = 16) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 0.6
	particles.amount = amount
	particles.lifetime = 1.4
	particles.direction = Vector2.UP
	particles.spread = 40.0
	particles.gravity = Vector2(0, -40)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 90.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = color
	particles.z_index = 50
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = fade
	scene.add_child(particles)
	particles.global_position = world_position
	particles.emitting = true
	get_tree().create_timer(particles.lifetime + 0.3).timeout.connect(particles.queue_free)


# --- Combinaciones listas para usar ---------------------------------------------

## Un enemigo recibió un golpe pero sigue vivo.
func enemy_hit(sprite: CanvasItem) -> void:
	flash(sprite)
	AudioManager.play("hit", -4.0, 0.12)


## Un enemigo murió (big = true para un enemigo muy grande: más temblor y explosión).
func enemy_died(world_position: Vector2, big: bool = false) -> void:
	if big:
		burst(world_position, Color(1.0, 0.6, 0.2), 40, 420.0, 8.0)
		shake(16.0, 0.7)
		hit_stop(0.18)
		AudioManager.play("explosion")
	else:
		burst(world_position, Color(0.9, 0.15, 0.2), 14)
		shake(4.0, 0.12)
		hit_stop(0.035)
		AudioManager.play("enemy_die", -3.0, 0.1)


## El jugador recibió daño: destello rojo, temblor fuerte, pausa breve y sonido.
func player_hurt(sprite: CanvasItem) -> void:
	flash(sprite, Color(2.5, 0.35, 0.35), 0.3)
	shake(10.0, 0.3)
	hit_stop(0.07)
	AudioManager.play("player_hurt")
