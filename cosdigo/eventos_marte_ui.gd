extends Control
## EVENTOS CLIMÁTICOS DE MARTE (tornado, tormenta solar, erupción solar, polvo marciano).
## - Aparecen solos de vez en cuando (o con las teclas 1-4 / botones de prueba).
## - Se PAUSAN mientras haya un minijuego abierto o una alarma del sistema de turnos.
## - Cada evento abre un minijuego simple (escena editable en res://scenes/minigames/).
## - El resultado afecta los recursos de GameState (barras del HUD).
## El original quedó respaldado en res://respaldo/eventos_marte_ui_original.txt

# Mismos números que antes: Pedro usa 1 (tornado: lo arrastra) y 4 (polvo: camina lento).
enum Evento { NINGUNO, TORNADO_RANDOM_KEY, TORMENTA_BARRA, ERUPCION_CIRCULO, POLVO_ESPACIO }

## Configuración editable de cada evento:
## escena = minijuego en res://scenes/minigames/, recurso = barra que baja,
## dano = cuánto baja si fallas del todo (se reduce según tu puntaje), tiempo = segundos para jugar.
const CONFIG := {
	Evento.TORNADO_RANDOM_KEY: {
		'nombre': 'Caught in a Dust Devil!', 'escena': 'tecla_random',
		'recurso': 'proteccion', 'dano': 10.0, 'tiempo': 5.0,
		'dato': 'Martian dust devils roam frequently; rovers have photographed hundreds across the plains.'},
	Evento.TORMENTA_BARRA: {
		'nombre': 'Solar Dust Storm', 'escena': 'barra_zona',
		'recurso': 'energia', 'dano': 8.0, 'tiempo': 7.0,
		'dato': 'Atmospheric dust obscures the sun, sharply dropping solar panel power generation.'},
	Evento.ERUPCION_CIRCULO: {
		'nombre': 'Solar Flare Alert', 'escena': 'circulo',
		'recurso': 'proteccion', 'dano': 10.0, 'tiempo': 7.0,
		'dato': 'Mars lacks a global intrinsic magnetic field, exposing the surface to intense radiation surges.'},
	Evento.POLVO_ESPACIO: {
		'nombre': 'Martian Dust Intrusion', 'escena': 'mantener',
		'recurso': 'energia', 'dano': 6.0, 'tiempo': 6.0,
		'dato': 'Abrasive Martian dust clings to solar arrays and equipment, requiring immediate manual purging.'},
}

const NOMBRE_RECURSO := {'energia': 'Energy', 'aire': 'Oxygen', 'agua': 'Water', 'alimentos': 'Food', 'proteccion': 'Shielding'}

@export var intervalo_min: float = 15.0   # mínimo 15 segundos entre eventos automáticos
@export var intervalo_max: float = 22.0
@export var mostrar_botones_prueba: bool = true

var jugador: CharacterBody2D = null
var evento_actual: int = Evento.NINGUNO
var cooldown_tornado: float = 3.0
var tiempo_siguiente_evento: float = 15.0 # deja que el primer evento de turno ocurra a los 15s
var nodo_tornado: Node2D = null

var _mini: Node = null
var _texto_resultado := ''
var _color_resultado := Color.WHITE
var _tiempo_mensaje := 0.0
var _particulas: Array[Vector2] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # no bloquea clics al mundo ni a las estaciones
	tiempo_siguiente_evento = randf_range(intervalo_min, intervalo_max)
	for i in range(40):
		_particulas.append(Vector2(randf() * 1280.0, randf() * 720.0))
	if mostrar_botones_prueba:
		_crear_botones_prueba()
	_preparar_tornado_en_mapa()

func _crear_botones_prueba() -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override('separation', 6)
	add_child(hbox)
	var configs := [
		['1: Dust Devil', Evento.TORNADO_RANDOM_KEY],
		['2: Dust Storm', Evento.TORMENTA_BARRA],
		['3: Solar Flare', Evento.ERUPCION_CIRCULO],
		['4: Dust Purge', Evento.POLVO_ESPACIO],
	]
	for cfg in configs:
		var btn := Button.new()
		btn.text = cfg[0]
		btn.focus_mode = Control.FOCUS_NONE
		var ev: int = cfg[1]
		btn.pressed.connect(func(): iniciar_evento(ev, true))
		hbox.add_child(btn)
	# Arriba a la derecha, para no tapar las barras del HUD
	hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hbox.position = Vector2(-hbox.get_combined_minimum_size().x - 12.0, 10.0)

func _preparar_tornado_en_mapa() -> void:
	if jugador == null or jugador.get_parent() == null:
		return
	var escena := jugador.get_parent()
	for nombre in ['tornado m', 'caminito tornadito']:
		if escena.has_node(nombre):
			nodo_tornado = escena.get_node(nombre)
			return

# ---------------------------------------------------------------- pausa

func _hay_minijuego_abierto() -> bool:
	var host := get_tree().get_first_node_in_group('minijuego_host')
	return host != null and host.get_child_count() > 0

## True si el sistema de turnos o cualquier minijuego está activo (para pausar eventos automáticos).
func _sistema_ocupado() -> bool:
	if GameState.partida_terminada():
		return true
	if _hay_minijuego_abierto():
		return true
	for s in get_tree().get_nodes_in_group('estaciones'):
		if is_instance_valid(s) and s.get('_alarma_activa') == true:
			return true
	return false

func _obtener_host() -> Node:
	var host := get_tree().get_first_node_in_group('minijuego_host')
	return host if host != null else self

# ---------------------------------------------------------------- eventos

func iniciar_evento(nuevo: int, forzado: bool = false) -> void:
	if evento_actual != Evento.NINGUNO or not CONFIG.has(nuevo):
		return
	# Si ya hay un minijuego en pantalla, esperar a que termine (uno por uno)
	if _hay_minijuego_abierto():
		if nuevo == Evento.TORNADO_RANDOM_KEY:
			cooldown_tornado = 2.0
		return
	if not forzado and _sistema_ocupado() and nuevo != Evento.TORNADO_RANDOM_KEY:
		return
	var cfg: Dictionary = CONFIG[nuevo]
	var escena: PackedScene = load('res://scenes/minigames/%s.tscn' % cfg['escena'])
	if escena == null:
		return
	evento_actual = nuevo
	GameState.sonar_alarma('clima')
	GameState.decir("🌪️ WEATHER ALARM! %s" % cfg['nombre'])
	GameState.actualizar_estado_evento(0.0, "🌪️ IN PROGRESS: %s" % cfg['nombre'])
	var mini := escena.instantiate()
	mini.set('tiempo_limite', cfg['tiempo'])
	_obtener_host().add_child(mini)
	mini.terminado.connect(_on_minijuego_terminado.bind(nuevo))
	mini.iniciar({'nombre': cfg['nombre'], 'minijuego': cfg['escena'], 'aviso': cfg['dato']})
	_mini = mini
	if nuevo == Evento.TORNADO_RANDOM_KEY and is_instance_valid(nodo_tornado):
		if nodo_tornado.has_method('activar_tornado') and not bool(nodo_tornado.get('activo')):
			nodo_tornado.activar_tornado()
	queue_redraw()

func _on_minijuego_terminado(puntaje: float, ev: int) -> void:
	evento_actual = Evento.NINGUNO
	_mini = null
	tiempo_siguiente_evento = randf_range(intervalo_min, intervalo_max)
	cooldown_tornado = 8.0
	# Reiniciar cuenta regresiva a 15 segundos para que no salga otro evento de inmediato
	GameState.actualizar_estado_evento(GameState.INTERVALO_EVENTOS, '')
	if ev == Evento.TORNADO_RANDOM_KEY and is_instance_valid(nodo_tornado) and nodo_tornado.has_method('desactivar_tornado'):
		nodo_tornado.desactivar_tornado()

	var cfg: Dictionary = CONFIG[ev]
	var dano := roundf(float(cfg['dano']) * (1.0 - puntaje))
	var mensaje: String = cfg['dato']
	if dano > 0.0 and not GameState.partida_terminada():
		GameState.cambiar(cfg['recurso'], -dano, cfg['nombre'])
		mensaje += '  (%s -%d)' % [NOMBRE_RECURSO.get(cfg['recurso'], cfg['recurso']), int(dano)]
	GameState.decir(mensaje)

	if puntaje >= 0.6:
		_texto_resultado = 'CLEARED!'
		_color_resultado = Color(0.3, 1.0, 0.4)
	else:
		_texto_resultado = 'IMPACT!'
		_color_resultado = Color(1.0, 0.3, 0.3)
		if jugador != null:
			if jugador.has_method('recibir_dano'):
				jugador.recibir_dano(25)
			if ev == Evento.TORMENTA_BARRA or ev == Evento.TORNADO_RANDOM_KEY:
				jugador.velocity = Vector2(240.0, -140.0)
				jugador.move_and_slide()
	_tiempo_mensaje = 1.8
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	# Teclas de prueba 1-4 (funcionan siempre que no haya otro minijuego abierto)
	if evento_actual != Evento.NINGUNO or _hay_minijuego_abierto():
		return
	var mapa := {KEY_1: Evento.TORNADO_RANDOM_KEY, KEY_2: Evento.TORMENTA_BARRA, KEY_3: Evento.ERUPCION_CIRCULO, KEY_4: Evento.POLVO_ESPACIO}
	if mapa.has(event.keycode):
		get_viewport().set_input_as_handled()
		iniciar_evento(mapa[event.keycode], true)

func _process(delta: float) -> void:
	if cooldown_tornado > 0.0:
		cooldown_tornado -= delta
	if _tiempo_mensaje > 0.0:
		_tiempo_mensaje -= delta
		queue_redraw()

	# Si el minijuego desapareció por otra razón, liberar el evento
	if evento_actual != Evento.NINGUNO and not is_instance_valid(_mini):
		evento_actual = Evento.NINGUNO

	if evento_actual == Evento.NINGUNO:
		if _sistema_ocupado():
			tiempo_siguiente_evento = maxf(tiempo_siguiente_evento, 15.0)
			return  # pausa y garantiza 15 s después de cualquier misión/evento de turno
		tiempo_siguiente_evento -= delta
		if tiempo_siguiente_evento <= 0.0:
			var opciones := [Evento.TORMENTA_BARRA, Evento.ERUPCION_CIRCULO, Evento.POLVO_ESPACIO]
			iniciar_evento(opciones[randi() % opciones.size()])
		return

	if evento_actual == Evento.TORNADO_RANDOM_KEY:
		_procesar_tornado()
	queue_redraw()

# ---------------------------------------------------------------- tornado (arrastre)

func _pos_jugador() -> Vector2:
	if jugador == null:
		return Vector2.ZERO
	if jugador.has_method('obtener_posicion_visual'):
		return jugador.obtener_posicion_visual()
	return jugador.global_position

func _pos_tornado() -> Vector2:
	if is_instance_valid(nodo_tornado):
		if nodo_tornado.has_method('obtener_posicion_visual'):
			return nodo_tornado.obtener_posicion_visual()
		return nodo_tornado.global_position
	return _pos_jugador()

func _procesar_tornado() -> void:
	if jugador == null:
		return
	var pos_jug := _pos_jugador()
	if is_instance_valid(nodo_tornado) and nodo_tornado.has_method('esta_en_nave') and nodo_tornado.esta_en_nave(pos_jug):
		return
	var diferencia := _pos_tornado() - pos_jug
	if diferencia.length() > 4.0 and diferencia.length() < 500.0:
		jugador.velocity = diferencia * 3.0
	else:
		jugador.velocity = Vector2(80.0, -45.0)
	jugador.move_and_slide()

# ---------------------------------------------------------------- efectos visuales

func _draw() -> void:
	var vp := get_viewport_rect().size
	if _tiempo_mensaje > 0.0 and evento_actual == Evento.NINGUNO:
		var font := ThemeDB.fallback_font
		var pos := Vector2(vp.x * 0.5 - 90.0, vp.y * 0.2)
		draw_string_outline(font, pos, _texto_resultado, HORIZONTAL_ALIGNMENT_CENTER, 180, 34, 6, Color.BLACK)
		draw_string(font, pos, _texto_resultado, HORIZONTAL_ALIGNMENT_CENTER, 180, 34, _color_resultado)
		return
	match evento_actual:
		Evento.TORMENTA_BARRA:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.55, 0.1, 0.16), true)
			for i in _particulas.size():
				_particulas[i].x = fmod(_particulas[i].x + 14.0, vp.x)
				draw_line(_particulas[i], _particulas[i] + Vector2(28, -4), Color(1.0, 0.75, 0.2, 0.55), 3.0)
		Evento.ERUPCION_CIRCULO:
			var pulso := 0.12 + 0.12 * absf(sin(float(Time.get_ticks_msec()) * 0.008))
			draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.15, 0.05, pulso), true)
		Evento.POLVO_ESPACIO:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.75, 0.28, 0.12, 0.28), true)
