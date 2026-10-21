class_name WeaponData
extends Resource
## Datos de un arma. Cada arma es un archivo .tres con estos valores.
## El jugador no "sabe" disparar de una forma fija: lee estos datos del arma equipada.

## Nombre que se muestra en el HUD.
@export var weapon_name: String = "Freud Boy"
## Daño que hace cada proyectil.
@export var damage: int = 1
## Disparos por segundo (cadencia).
@export var fire_rate: float = 4.0
## Velocidad del proyectil en píxeles por segundo.
@export var bullet_speed: float = 600.0
## Segundos que vive el proyectil antes de desaparecer (define el alcance).
@export var bullet_lifetime: float = 1.0
## Proyectiles por disparo (1 = pistola, 5 = escopeta).
@export var bullets_per_shot: int = 1
## Dispersión máxima en grados (0 = puntería perfecta).
@export var spread_degrees: float = 0.0
## Imagen del arma en el suelo (si queda vacía se usa la imagen por defecto).
@export var icon: Texture2D

@export_group("Bomba")
## Si es true, el arma lanza una bomba en vez de disparar balas.
## Usa bullet_speed como velocidad del lanzamiento y bullet_lifetime como tiempo máximo
## de vuelo (alcance = velocidad x tiempo). fire_rate es lanzamientos por segundo.
@export var is_bomb: bool = false
## Radio de la explosión en píxeles (solo bombas).
@export var blast_radius: float = 120.0
## Escena de la bomba (Bomb.tscn, solo bombas).
@export var bomb_scene: PackedScene
