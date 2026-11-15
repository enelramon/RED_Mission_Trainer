extends Area2D

var velocidad = 150.0
var direccion = Vector2(1, 1).normalized() # Dirección inicial en diagonal

func _process(delta):
	# Mueve el tornado constantemente frame a frame
	position += direccion * velocidad * delta

# Esta función se activa cuando el tornado choca con un cuerpo físico
func _on_body_entered(body):
	# --- LÍNEA DE DEPURACIÓN (Mira la consola de Godot al jugar) ---
	print("El tornado chocó con: ", body.name)
	
	# Verifica si lo que tocó es el jugador
	if body is CharacterBody2D or body.name == "CharacterBody2D" or body.name == "Pedro" or body.name == "AnimatedSprite2D": 
		print("¡El tornado atrapó al jugador!")
		
		# 1. Intentamos quitarle vida usando la función que creaste en el jugador
		if body.has_method("recibir_dano"):
			body.recibir_dano(25)
		
		# 2. Empujamos al jugador fuertemente
		body.velocity = direccion * 1500
		body.move_and_slide()
		
	else:
		# Si no es el jugador, asumimos que son las paredes del mapa. 
		# Hacemos que el tornado rebote cambiando su dirección al azar.
		direccion = direccion.rotated(deg_to_rad(randf_range(120, 240)))
