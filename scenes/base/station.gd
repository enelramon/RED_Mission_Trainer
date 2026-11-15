extends Area2D
class_name Station
## Una por sistema (según la guía PDF). Muestra la versión normal o mejorada
## y recibe las alarmas de su estación una por una.

signal minijuego_terminado(puntaje: float)

@export var sistema_id: String = 'energia'
@export var tiempo_limite: float = 35.0
@export var radio_interaccion: float = 195.0

@onready var sprite_normal: Node2D = $SpriteNormal
@onready var sprite_mejorada: Node2D = $SpriteMejorada
@onready var alarma: Node2D = $Alarma

var _evento: Dictionary = {}
var _alarma_activa := false
var _minijuego_abierto := false
var _jugador_cerca := false
var _fisica_cerca := false
var _id_alarma := 0
var _temporizador_pitido := 0.0

var _lbl_titulo: Label = null
var _lbl_prompt: Label = null
var _tiempo_pulso := 0.0

const COLORES_SISTEMA := {
	'energia': Color(1.0, 0.85, 0.2),
	'aire': Color(0.65, 0.9, 1.0),
	'agua': Color(0.25, 0.65, 1.0),
	'alimentos': Color(0.35, 0.9, 0.4),
	'proteccion': Color(1.0, 0.4, 0.35),
	'animo': Color(0.95, 0.75, 0.95)
}

const ICONOS_SISTEMA := {
	'energia': preload("res://Fotos/Separados/Iconos/icono_energia.png"),
	'aire': preload("res://Fotos/Separados/Iconos/icono_aire.png"),
	'agua': preload("res://Fotos/Separados/Iconos/icono_agua.png"),
	'alimentos': preload("res://Fotos/Separados/Iconos/icono_alimentos.png"),
	'proteccion': preload("res://Fotos/Separados/Iconos/icono_proteccion.png"),
}

const TEX_ALERTA := preload("res://art/alerta.png")

func _ready() -> void:
	add_to_group('estaciones')
	var tex: Texture2D = ICONOS_SISTEMA.get(sistema_id)
	if tex != null:
		if sprite_normal is Sprite2D:
			sprite_normal.texture = tex
			sprite_normal.modulate = Color(1.0, 1.0, 1.0, 0.95)
			sprite_normal.scale = Vector2(2.2, 2.2)
		if sprite_mejorada is Sprite2D:
			sprite_mejorada.texture = tex
			sprite_mejorada.modulate = Color(1.15, 1.15, 1.15, 1.0)
			sprite_mejorada.scale = Vector2(2.6, 2.6)
	if alarma is Sprite2D:
		alarma.texture = TEX_ALERTA
		alarma.modulate = Color(1.0, 1.0, 1.0, 1.0)
		alarma.scale = Vector2(0.75, 0.75)

	var mejorado := GameState.esta_mejorado(sistema_id)
	sprite_mejorada.visible = mejorado
	sprite_normal.visible = not mejorado
	alarma.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	_crear_carteles_visuales()

func _crear_carteles_visuales() -> void:
	var info: Dictionary = GameData.sistemas.get(sistema_id, {})
	var nombre: String = info.get('nombre', sistema_id.capitalize())
	var mejorado := GameState.esta_mejorado(sistema_id)
	var col: Color = COLORES_SISTEMA.get(sistema_id, Color.WHITE)

	_lbl_titulo = Label.new()
	_lbl_titulo.text = "%s%s" % [nombre.to_upper(), " [UPGRADED]" if mejorado else ""]
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.position = Vector2(-110, 26)
	_lbl_titulo.custom_minimum_size = Vector2(220, 24)
	_lbl_titulo.add_theme_font_size_override("font_size", 13)
	_lbl_titulo.add_theme_color_override("font_color", col)
	_lbl_titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_lbl_titulo.add_theme_constant_override("outline_size", 5)
	add_child(_lbl_titulo)

	_lbl_prompt = Label.new()
	_lbl_prompt.text = "⚠ [E] REPAIR ALARM!"
	_lbl_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_prompt.position = Vector2(-150, -62)
	_lbl_prompt.custom_minimum_size = Vector2(300, 30)
	_lbl_prompt.add_theme_font_size_override("font_size", 15)
	_lbl_prompt.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35))
	_lbl_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.98))
	_lbl_prompt.add_theme_constant_override("outline_size", 6)
	_lbl_prompt.visible = false
	add_child(_lbl_prompt)

func _process(delta: float) -> void:
	_tiempo_pulso += delta * 6.0
	_actualizar_proximidad_jugador()

	if _alarma_activa:
		alarma.visible = true
		var escala_pulso := 0.75 + 0.12 * sin(_tiempo_pulso)
		alarma.scale = Vector2(escala_pulso, escala_pulso)
		if _lbl_titulo != null:
			_lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2) if int(_tiempo_pulso) % 2 == 0 else Color(1.0, 0.9, 0.2))
		if not _minijuego_abierto:
			_temporizador_pitido -= delta
			if _temporizador_pitido <= 0.0:
				_temporizador_pitido = 5.5
				GameState.sonar_alarma('estacion')

	if _lbl_prompt != null:
		# Solo se muestra cuando ESTA estación tiene la misión/alarma activa (una a la vez)
		_lbl_prompt.visible = _alarma_activa and not _minijuego_abierto
		if _alarma_activa:
			var nombre_ev: String = _evento.get('nombre', 'Alarma')
			if _jugador_cerca:
				_lbl_prompt.text = "🚨 [E] REPAIR: %s" % nombre_ev
				_lbl_prompt.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4))
			else:
				_lbl_prompt.text = "🚨 ALARM HERE! (%s) — Approach and press [E]" % nombre_ev
				_lbl_prompt.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))

func _actualizar_proximidad_jugador() -> void:
	var cerca := _fisica_cerca
	if not cerca:
		for j in get_tree().get_nodes_in_group('jugador'):
			if j is Node2D:
				var pos_j: Vector2 = j.global_position
				if j.has_method('obtener_posicion_visual'):
					pos_j = j.obtener_posicion_visual()
				elif j.has_node('Animacion de pedro'):
					pos_j = j.get_node('Animacion de pedro').global_position
				if pos_j.distance_to(global_position) <= radio_interaccion:
					cerca = true
					break
	_jugador_cerca = cerca

func _on_body_entered(b: Node) -> void:
	if b.is_in_group('jugador'):
		_fisica_cerca = true
		_jugador_cerca = true

func _on_body_exited(b: Node) -> void:
	if b.is_in_group('jugador'):
		_fisica_cerca = false

func activar_alarma(evento: Dictionary) -> void:
	_evento = evento
	_alarma_activa = true
	_minijuego_abierto = false
	alarma.visible = true
	_temporizador_pitido = 5.5
	_id_alarma += 1
	var id_actual := _id_alarma
	GameState.sonar_alarma('estacion')
	get_tree().create_timer(tiempo_limite).timeout.connect(func(): _on_tiempo_agotado(id_actual))

func cancelar_alarma_externa() -> void:
	_alarma_activa = false
	_minijuego_abierto = false
	alarma.visible = false
	var col: Color = COLORES_SISTEMA.get(sistema_id, Color.WHITE)
	if _lbl_titulo != null:
		_lbl_titulo.add_theme_color_override("font_color", col)

func _on_tiempo_agotado(id_esperado: int) -> void:
	if _alarma_activa and not _minijuego_abierto and _id_alarma == id_esperado:
		_cerrar(0.0) # el jugador no llegó a tiempo

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _alarma_activa and not _minijuego_abierto and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_abrir_minijuego()

func _unhandled_input(event: InputEvent) -> void:
	if not _alarma_activa or _minijuego_abierto:
		return
	var pulsa_interactuar := event.is_action_pressed('interactuar')
	if not pulsa_interactuar and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_F, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] or event.physical_keycode in [KEY_E, KEY_F]:
			pulsa_interactuar = true

	if pulsa_interactuar and _jugador_cerca:
		get_viewport().set_input_as_handled()
		_abrir_minijuego()

func _abrir_minijuego() -> void:
	if _minijuego_abierto:
		return
	var host := get_tree().get_first_node_in_group('minijuego_host')
	if host != null and host.get_child_count() > 0:
		return
	_minijuego_abierto = true
	var nombre_mini: String = _evento.get('minijuego', 'barra_zona')
	if nombre_mini == 'ninguno' or nombre_mini.is_empty():
		nombre_mini = 'barra_zona'
	var escena: PackedScene = load('res://scenes/minigames/%s.tscn' % nombre_mini)
	var mini: Minijuego = escena.instantiate()
	host.add_child(mini)
	mini.terminado.connect(_cerrar)
	mini.iniciar(_evento)

func _cerrar(puntaje: float) -> void:
	_alarma_activa = false
	_minijuego_abierto = false
	alarma.visible = false
	var col: Color = COLORES_SISTEMA.get(sistema_id, Color.WHITE)
	if _lbl_titulo != null:
		_lbl_titulo.add_theme_color_override("font_color", col)
	minijuego_terminado.emit(puntaje)
