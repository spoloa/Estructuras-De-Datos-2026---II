extends Node
## Sonidos y música del juego.
##
## Se registra como Autoload con el nombre "AudioManager", por eso NO declara class_name.
##
## Uso:
##   AudioManager.play("shoot")                 efecto de sonido (varios a la vez)
##   AudioManager.play("hit", -4.0, 0.1)        volumen en dB y variación de tono (0.1 = ±10 %)
##   AudioManager.play_music("menu")            cambia la música con fundido
##   AudioManager.stop_music()
##
## Los archivos están en assets/sfx y assets/musica. Si falta alguno solo se avisa en consola.

## Efectos: nombre -> archivo.
const SFX := {
	"shoot": "res://assets/sfx/shoot.wav",
	"swing": "res://assets/sfx/swing.wav",
	"hit": "res://assets/sfx/hit.wav",
	"enemy_die": "res://assets/sfx/enemy_die.wav",
	"player_hurt": "res://assets/sfx/player_hurt.wav",
	"player_death": "res://assets/sfx/player_death.wav",
	"pickup": "res://assets/sfx/pickup.wav",
	"click": "res://assets/sfx/click.wav",
	"wave_start": "res://assets/sfx/wave_start.wav",
	"wave_clear": "res://assets/sfx/wave_clear.wav",
	"explosion": "res://assets/sfx/explosion.wav",
	"combo": "res://assets/sfx/combo.wav",
	"victory": "res://assets/sfx/victory.wav",
	"defeat": "res://assets/sfx/defeat.wav",
}
## Música: nombre -> archivo.
const MUSIC := {
	"menu": "res://assets/musica/menu.wav",
	"game": "res://assets/musica/bienvenidoalapatriamilagro.mp3",
}
## Volumen de cada música en dB (ajusta aquí si alguna suena muy fuerte).
const MUSIC_VOLUME := {"menu": -6.0, "game": 0.0}
## Cuántos efectos pueden sonar a la vez.
const POOL_SIZE: int = 14
## Segundos mínimos entre dos veces el mismo efecto (evita que 10 disparos suenen como ruido).
const MIN_REPEAT: float = 0.04

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _last_played: Dictionary = {}
var _music: AudioStreamPlayer
var _music_name: String = ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sigue sonando con el juego en pausa
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	# La música es un bucle: al terminar vuelve a empezar (sirve para .wav y .mp3).
	_music.finished.connect(func() -> void:
		if _music_name != "":
			_music.play())


## Reproduce un efecto. volume_db: 0 = normal, negativo = más bajo. pitch_variation: variación aleatoria de tono.
func play(sound: String, volume_db: float = 0.0, pitch_variation: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _get_stream(sound, SFX)
	if stream == null:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < MIN_REPEAT:
		return
	_last_played[sound] = now
	var player: AudioStreamPlayer = _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = maxf(0.1, pitch * (1.0 + randf_range(-pitch_variation, pitch_variation)))
	player.play()


## Cambia la música con un fundido corto. Si ya suena esa, no hace nada.
func play_music(music_name: String, fade_time: float = 0.6) -> void:
	if music_name == _music_name and _music.playing:
		return
	var stream: AudioStream = _get_stream(music_name, MUSIC)
	if stream == null:
		return
	_music_name = music_name
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, fade_time * 0.5)
	_music_tween.tween_callback(func() -> void:
		_music.stream = stream
		_music.volume_db = -40.0
		_music.play())
	_music_tween.tween_property(_music, "volume_db", float(MUSIC_VOLUME.get(music_name, 0.0)), fade_time * 0.5)


## Apaga la música con un fundido.
func stop_music(fade_time: float = 0.8) -> void:
	_music_name = ""
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -40.0, fade_time)
	_music_tween.tween_callback(_music.stop)


## Nombre de la música que suena ("" si ninguna).
func current_music() -> String:
	return _music_name


## Carga (y recuerda) un sonido. Devuelve null si el nombre o el archivo no existen.
func _get_stream(sound: String, table: Dictionary) -> AudioStream:
	if not table.has(sound):
		push_warning("AudioManager: no existe el sonido '%s'" % sound)
		return null
	var path: String = table[sound]
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
		if _streams[path] == null:
			push_warning("AudioManager: falta el archivo %s" % path)
	return _streams[path]


## Un reproductor libre del grupo; si todos están ocupados, reutiliza el más antiguo.
func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return _pool[0]
