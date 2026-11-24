class_name WeaponData
extends Resource
## Datos de un arma. Cada arma es un archivo .tres con estos valores.
## El jugador no "sabe" disparar de una forma fija: lee estos datos del arma equipada.

## Cómo ataca el arma.
##   PROJECTILE -> dispara proyectiles (pistola, escopeta, bazuca).
##   MELEE      -> golpe cuerpo a cuerpo en un arco frente al jugador (bate).
enum AttackType { PROJECTILE, MELEE }

## Nombre que se muestra en el HUD.
@export var weapon_name: String = "Freud Boy"
## Daño que hace cada proyectil (o cada golpe, en las armas cuerpo a cuerpo).
@export var damage: int = 1
## Disparos (o golpes) por segundo (cadencia).
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
## Tipo de ataque del arma.
@export var attack_type: AttackType = AttackType.PROJECTILE

@export_group("Cohete (bazuca)")
## Escena del cohete (Rocket.tscn). Si queda vacía, el arma dispara balas normales.
@export var rocket_scene: PackedScene
## Radio de la explosión del cohete en píxeles (el daño se aplica en toda esa área).
@export var blast_radius: float = 0.0

@export_group("Cuerpo a cuerpo (bate)")
## Alcance del golpe en píxeles, medido desde el jugador.
@export var melee_range: float = 110.0
## Ancho del golpe en grados, centrado hacia donde apunta el mouse (360 = alrededor del jugador).
@export var melee_arc_degrees: float = 140.0
