extends Area2D

var velocidad: float = 115.0
var direccion: Vector2 = Vector2(1.0, -0.6).normalized()
var jugador: CharacterBody2D = null
var sprite_tornado: AnimatedSprite2D = null

# Estado de aparición intermitente (no siempre activo, mínimo 20 s entre apariciones)
var activo: bool = false
var temporizador_estado: float = 20.0
var duracion_activo_min: float = 10.0
var duracion_activo_max: float = 14.0
var duracion_inactivo_min: float = 20.0
var duracion_inactivo_max: float = 28.0

# Zona de la nave/base (con margen exterior) que el tornado NO puede atravesar
var zonas_naves: Array[Rect2] = [
	Rect2(-315.0, -5.0, 1200.0, 555.0)    # Nave principal (casa)
]

func _ready() -> void:
	if has_node("tornado"):
		sprite_tornado = $tornado
		if sprite_tornado.sprite_frames != null and sprite_tornado.sprite_frames.has_animation("default"):
			sprite_tornado.play("default")

	jugador = _buscar_jugador()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Iniciar oculto/inactivo para que solo aparezca de vez en cuando (tras 20 s)
	_establecer_activo(false)
	temporizador_estado = 20.0

func _establecer_activo(nuevo_estado: bool) -> void:
	activo = nuevo_estado
	visible = nuevo_estado
	monitoring = nuevo_estado
	monitorable = nuevo_estado

func _buscar_jugador() -> CharacterBody2D:
	var padre := get_parent()
	if padre == null:
		return null
	for nombre in ["Pedro", "CharacterBody2D", "AnimatedSprite2D"]:
		if padre.has_node(nombre) and padre.get_node(nombre) is CharacterBody2D:
			return padre.get_node(nombre)
	for child in padre.get_children():
		if child is CharacterBody2D:
			return child
	return null

func obtener_posicion_visual() -> Vector2:
	if sprite_tornado != null:
		return sprite_tornado.global_position
	return global_position

func _mover_posicion_visual(nueva_pos_global: Vector2) -> void:
	if sprite_tornado != null:
		var offset_hijo: Vector2 = sprite_tornado.global_position - global_position
		global_position = nueva_pos_global - offset_hijo
	else:
		global_position = nueva_pos_global

func esta_en_nave(punto: Vector2) -> bool:
	for rect in zonas_naves:
		if rect.has_point(punto):
			return true
	return false

func _hay_pared_entre(desde: Vector2, hasta: Vector2) -> bool:
	var mundo := get_world_2d()
	if mundo == null:
		return false
	var space := mundo.direct_space_state
	var query := PhysicsRayQueryParameters2D.create(desde, hasta)
	if jugador != null:
		query.exclude = [get_rid(), jugador.get_rid()]
	else:
		query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	return not hit.is_empty()

func _elegir_punto_aparicion(pos_referencia: Vector2) -> Vector2:
	# Intentar elegir un punto cerca del jugador pero SIEMPRE fuera de las naves
	for _i in range(25):
		var angulo: float = randf() * TAU
		var dist: float = randf_range(220.0, 420.0)
		var candidato: Vector2 = pos_referencia + Vector2(cos(angulo), sin(angulo)) * dist
		if not esta_en_nave(candidato):
			return candidato
	# Si el jugador está en medio de las naves, aparecer en la explanada exterior izquierda
	return Vector2(-580.0, randf_range(260.0, 680.0))

func activar_tornado() -> void:
	var pos_j: Vector2 = Vector2(-349.0, 269.0)
	if jugador != null:
		pos_j = jugador.obtener_posicion_visual() if jugador.has_method("obtener_posicion_visual") else jugador.global_position
	var spawn_pos: Vector2 = _elegir_punto_aparicion(pos_j)
	_mover_posicion_visual(spawn_pos)
	direccion = Vector2.RIGHT.rotated(randf() * TAU)
	_establecer_activo(true)
	temporizador_estado = randf_range(duracion_activo_min, duracion_activo_max)
	if GameState != null:
		GameState.sonar_alarma('clima')
		GameState.decir("🌪️ DUST DEVIL ALARM! A vortex of abrasive dust is approaching the habitat exterior.")

func desactivar_tornado() -> void:
	_establecer_activo(false)
	temporizador_estado = randf_range(duracion_inactivo_min, duracion_inactivo_max)

func _rebotar_fuera_de_nave(pos_actual: Vector2, pos_intentada: Vector2) -> void:
	for rect in zonas_naves:
		if rect.has_point(pos_intentada):
			var centro_rect: Vector2 = rect.get_center()
			var hacia_afuera: Vector2 = (pos_actual - centro_rect).normalized()
			if hacia_afuera == Vector2.ZERO:
				hacia_afuera = Vector2.LEFT
			direccion = hacia_afuera.rotated(randf_range(-0.35, 0.35)).normalized()
			# Empujar ligeramente hacia afuera si quedó muy al borde
			if rect.has_point(pos_actual):
				_mover_posicion_visual(pos_actual + hacia_afuera * 24.0)
			return
	# Si chocó con un muro físico por raycast
	direccion = (-direccion).rotated(randf_range(-0.5, 0.5)).normalized()

func _process(delta: float) -> void:
	if jugador == null:
		jugador = _buscar_jugador()

	# Ciclo de activación y desactivación del tornado
	temporizador_estado -= delta
	if not activo:
		if temporizador_estado <= 0.0:
			activar_tornado()
		return
	else:
		var ui_act = jugador.get("ui_eventos") if jugador != null else null
		# Si terminó su tiempo activo y no está arrastrando al jugador en este instante, desaparece
		if temporizador_estado <= 0.0 and (ui_act == null or ui_act.evento_actual != 1):
			desactivar_tornado()
			return

	# Calcular nueva posición y verificar que NO atraviese las paredes de ninguna nave
	var pos_tornado: Vector2 = obtener_posicion_visual()
	var paso: Vector2 = direccion * velocidad * delta
	var nueva_pos: Vector2 = pos_tornado + paso

	if esta_en_nave(nueva_pos) or _hay_pared_entre(pos_tornado, nueva_pos):
		_rebotar_fuera_de_nave(pos_tornado, nueva_pos)
	else:
		position += paso

	if jugador == null:
		return

	var pos_jugador: Vector2 = jugador.obtener_posicion_visual() if jugador.has_method("obtener_posicion_visual") else jugador.global_position
	pos_tornado = obtener_posicion_visual()
	var vector_a_jugador: Vector2 = pos_jugador - pos_tornado
	var distancia: float = vector_a_jugador.length()

	# Si el jugador está afuera de la nave y lejos, el tornado se orienta hacia él
	if distancia > 420.0 and not esta_en_nave(pos_jugador):
		var dir_hacia_j: Vector2 = vector_a_jugador.normalized().rotated(randf_range(-0.35, 0.35))
		if not esta_en_nave(pos_tornado + dir_hacia_j * 32.0):
			direccion = dir_hacia_j

	var ui = jugador.get("ui_eventos")
	if ui == null:
		return

	# Si el jugador está protegido dentro de la nave, el tornado NO lo puede atrapar a través del muro
	if esta_en_nave(pos_jugador):
		return

	# Si está afuera y el tornado se acerca, activa el evento 1
	if distancia < 55.0 and ui.evento_actual == 0 and ui.cooldown_tornado <= 0.0:
		print("¡El tornado atrapó al jugador!")
		ui.iniciar_evento(1)

func _on_body_entered(body: Node2D) -> void:
	if not activo:
		return
	if body is CharacterBody2D or body.name == "CharacterBody2D" or body.name == "Pedro" or body.name == "AnimatedSprite2D":
		var pos_b: Vector2 = body.obtener_posicion_visual() if body.has_method("obtener_posicion_visual") else body.global_position
		if esta_en_nave(pos_b):
			return
		var ui = body.get("ui_eventos")
		if ui != null and ui.evento_actual == 0 and ui.cooldown_tornado <= 0.0:
			ui.iniciar_evento(1)
	else:
		direccion = direccion.rotated(deg_to_rad(randf_range(135.0, 225.0)))
