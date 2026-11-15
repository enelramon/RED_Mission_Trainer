extends CharacterBody2D

const SPEED: float = 200.0
var vida: int = 100
var anim: AnimatedSprite2D = null
var ui_eventos = null

func _ready() -> void:
	add_to_group("jugador")

	# 1. Buscar automáticamente el nodo AnimatedSprite2D dentro del personaje
	if has_node("AnimatedSprite2D"):
		anim = $AnimatedSprite2D
	else:
		for child in get_children():
			if child is AnimatedSprite2D:
				anim = child
				break

	# 2. Crear la capa de eventos climáticos (convive con el sistema de turnos: se pausa sola)
	if true:
		var capa_ui = CanvasLayer.new()
		capa_ui.name = "CapaEventosMarte"
		add_child(capa_ui)

		var ruta_ui: String = "res://cosdigo/eventos_marte_ui.gd"
		if not ResourceLoader.exists(ruta_ui):
			ruta_ui = "res://eventos_marte_ui.gd"

		if ResourceLoader.exists(ruta_ui):
			var script_eventos = load(ruta_ui)
			if script_eventos != null:
				ui_eventos = script_eventos.new()
				ui_eventos.jugador = self
				capa_ui.add_child(ui_eventos)

func _physics_process(_delta: float) -> void:
	# Si el tornado te está arrastrando (evento 1), el movimiento lo controla el tornado hasta que presiones la tecla random
	if ui_eventos != null and ui_eventos.evento_actual == 1:
		return

	# 1. Obtener la dirección (flechas o WASD)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir == Vector2.ZERO:
		var x: int = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
		var y: int = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
		input_dir = Vector2(x, y).normalized()

	# Si está activo el Polvo Marciano (evento 4), caminas más lento hasta mantener Espacio
	var velocidad_actual: float = SPEED
	if ui_eventos != null and ui_eventos.evento_actual == 4:
		velocidad_actual = SPEED * 0.3

	# 2. Aplicar movimiento normal
	velocity = input_dir * velocidad_actual
	move_and_slide()

	# 3. Actualizar animación según la dirección
	actualizar_animacion(input_dir)

func actualizar_animacion(dir: Vector2) -> void:
	if anim == null:
		return

	if dir == Vector2.ZERO:
		anim.stop()
		anim.frame = 0
		return

	if absf(dir.x) > absf(dir.y):
		if dir.x > 0.0:
			reproducir("caminata para la derecha")
		else:
			reproducir("caminata para la izquierda")
	else:
		if dir.y > 0.0:
			reproducir("caminata para abajo")
		else:
			reproducir("caminata para arriba")

func reproducir(nombre: String) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(nombre):
		anim.play(nombre)
	elif anim.sprite_frames.has_animation(nombre + " "):
		anim.play(nombre + " ")

func obtener_posicion_visual() -> Vector2:
	if anim != null:
		return anim.global_position
	return global_position

func recibir_dano(cantidad: int) -> void:
	vida -= cantidad
	print("¡Auch! La vida bajó a: ", vida)
	if vida <= 0:
		print("¡Marquitos ha sido destruido!")
