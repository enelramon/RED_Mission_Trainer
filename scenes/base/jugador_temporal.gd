extends CharacterBody2D
## Jugador temporal: se mueve con las flechas del teclado.

const VELOCIDAD := 200.0

func _physics_process(_delta: float) -> void:
	var direccion := Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	velocity = direccion * VELOCIDAD
	move_and_slide()
