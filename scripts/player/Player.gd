extends CharacterBody2D

## Jugador: movimiento en 8 direcciones en tiempo real. 
## Velocidad en píxeles por segundo (editable desde el Inspector). 
@export var speed: float = 300.0 

func _physics_process(_delta: float) -> void: 
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") 
	velocity = direction * speed 
	move_and_slide()
