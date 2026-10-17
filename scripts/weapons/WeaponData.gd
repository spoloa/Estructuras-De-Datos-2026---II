class_name WeaponData
extends Resource
## Datos de un arma. Cada arma es un archivo .tres con estos valores.
## El jugador no "sabe" disparar de una forma fija: lee estos datos del arma equipada.

## Nombre que se muestra en el HUD.
@export var weapon_name: String = "Pistola"
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
