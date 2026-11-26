extends Node
## Perfil del jugador: guarda el nickname en disco para que el juego lo recuerde
## cada vez que se abre (un "inicio de sesión" simple, sin contraseña).
##
## Se registra como Autoload con el nombre "PlayerProfile" (Proyecto > Configuración
## del proyecto > Globales), por eso este script NO declara class_name.
##
## Se guarda en user://profile.save (formato JSON, texto legible).
## La primera vez no hay archivo: el menú principal pide el nombre (NicknameScreen).

## Se emite cuando cambia el nickname.
signal nickname_changed(new_nickname: String)

const SAVE_PATH: String = "user://profile.save"
## Largo máximo del nickname (la tabla del ranking está pensada para este tamaño).
const MAX_LENGTH: int = 12
const MIN_LENGTH: int = 2

## Archivo que se usa para guardar y cargar (se puede cambiar en las pruebas).
var save_path: String = SAVE_PATH
## Nickname actual ("" si todavía no se ha elegido).
var nickname: String = ""


func _ready() -> void:
	load_profile()


## true si ya hay un nickname elegido.
func has_nickname() -> bool:
	return nickname != ""


## Limpia un nombre: quita espacios sobrantes y caracteres raros, y lo recorta a MAX_LENGTH.
## Solo se permiten letras, números, espacios, guion y guion bajo (incluye tildes y ñ).
func clean(raw: String) -> String:
	var result: String = ""
	for character in raw.strip_edges():
		var code: int = character.unicode_at(0)
		var is_letter: bool = (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 192 and code <= 255 and code != 215 and code != 247)
		var is_digit: bool = code >= 48 and code <= 57
		if is_letter or is_digit or character == " " or character == "-" or character == "_":
			result += character
	# Varios espacios seguidos se vuelven uno solo.
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.substr(0, MAX_LENGTH).strip_edges()


## true si el texto, ya limpio, sirve como nickname.
func is_valid(raw: String) -> bool:
	return clean(raw).length() >= MIN_LENGTH


## Cambia el nickname y lo guarda. Devuelve false (sin cambiar nada) si no es válido.
func set_nickname(raw: String) -> bool:
	var cleaned: String = clean(raw)
	if cleaned.length() < MIN_LENGTH:
		return false
	nickname = cleaned
	save_profile()
	nickname_changed.emit(nickname)
	return true


## Guarda el perfil. Devuelve false si no se pudo escribir.
func save_profile() -> bool:
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("PlayerProfile: no se pudo guardar el perfil (%s)" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify({"nickname": nickname}, "\t"))
	file.close()
	return true


## Carga el perfil. Si no existe (primera vez) o está dañado, queda sin nickname.
func load_profile() -> bool:
	nickname = ""
	if not FileAccess.file_exists(save_path):
		return true
	var json: JSON = JSON.new()  # a diferencia de JSON.parse_string, no imprime errores del motor
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("PlayerProfile: el archivo del perfil está dañado, se pedirá el nombre de nuevo")
		return false
	nickname = clean(str(json.data.get("nickname", "")))
	return true
