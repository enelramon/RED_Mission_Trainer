extends Sprite2D

@export var offset_lateral: Vector2 = Vector2(46.0, -14.0)
@export var velocidad_seguimiento: float = 6.5

var jugador: CharacterBody2D = null
var tiempo_vuelo: float = 0.0
var lado_actual: float = 1.0 # 1.0 = derecha del jugador, -1.0 = izquierda del jugador
var _capa_globo: CanvasLayer = null
var _globo_panel: PanelContainer = null
var _globo_label: Label = null
var _tiempo_restante_globo: float = 0.0

const TEX_GLOBO_ALERTA = preload("res://Fotos/Separados/Globos/globo_alerta.png")
const TEX_GLOBO_PENSAMIENTO = preload("res://Fotos/Separados/Globos/globo_pensamiento.png")
const TEX_GLOBO_DIALOGO = preload("res://Fotos/Separados/Globos/globo_dialogo.png")

var _estilo_alerta: StyleBoxTexture = null
var _estilo_pensamiento: StyleBoxTexture = null
var _estilo_dialogo: StyleBoxTexture = null

func _ready() -> void:
	jugador = _buscar_jugador()
	if jugador != null:
		jugador.add_to_group("jugador")
		var pos_j: Vector2 = _obtener_pos_jugador()
		global_position = pos_j + offset_lateral
	_crear_globo_dialogo()
	if GameState != null and GameState.has_signal("robot_dice"):
		GameState.robot_dice.connect(_on_robot_dice)
	call_deferred("_asegurar_sistema_base")

func _asegurar_sistema_base() -> void:
	var raiz := get_parent()
	if raiz == null:
		return

	# Si no venimos de la pantalla de selección, inicializar partida de prueba
	if GameState.mejoras.is_empty():
		GameState.iniciar_partida(['energia', 'agua'])

	if not GameState.mision_terminada.is_connected(_on_mision_terminada_fallback):
		GameState.mision_terminada.connect(_on_mision_terminada_fallback)

	# Si el editor tenía abierta una versión anterior en memoria con la nave inferior, quitarla al instante
	for nodo_extra in ["casa_grande", "Casa_Grande_Objetos"]:
		if raiz.has_node(nodo_extra):
			var n_ex := raiz.get_node(nodo_extra)
			n_ex.visible = false
			n_ex.queue_free()

	if jugador != null and jugador.position.y > 350.0:
		jugador.position = Vector2(972.75, 105.0)
		global_position = Vector2(-303.0, 255.0)

	# Asegurar nodo Mundo y las 5 estaciones de la guía PDF en la nave principal
	var mundo: Node2D = raiz.get_node_or_null("Mundo")
	if mundo == null:
		mundo = Node2D.new()
		mundo.name = "Mundo"
		mundo.z_index = 2
		raiz.add_child(mundo)

	for st_extra in ["EstacionAnimo", "EstacionAgua2", "EstacionProteccion2", "EstacionEnergia2", "EstacionAire2", "EstacionAnimo2", "EstacionAlimentos2"]:
		if mundo.has_node(st_extra):
			var n_st := mundo.get_node(st_extra)
			n_st.remove_from_group("estaciones")
			n_st.visible = false
			n_st.queue_free()

	var st_scn: PackedScene = load("res://scenes/base/station.tscn")
	var lista_estaciones := [
		{"nombre": "EstacionAgua", "id": "agua", "pos": Vector2(-180, 155), "radio": 195.0},
		{"nombre": "EstacionProteccion", "id": "proteccion", "pos": Vector2(280, 155), "radio": 195.0},
		{"nombre": "EstacionEnergia", "id": "energia", "pos": Vector2(690, 155), "radio": 195.0},
		{"nombre": "EstacionAire", "id": "aire", "pos": Vector2(-180, 425), "radio": 195.0},
		{"nombre": "EstacionAlimentos", "id": "alimentos", "pos": Vector2(650, 415), "radio": 195.0},
	]
	for cfg in lista_estaciones:
		if not mundo.has_node(cfg["nombre"]):
			var st = st_scn.instantiate()
			st.name = cfg["nombre"]
			st.sistema_id = cfg["id"]
			st.position = cfg["pos"]
			st.radio_interaccion = cfg["radio"]
			mundo.add_child(st)

	if not raiz.has_node("HUD"):
		var hud_scn: PackedScene = load("res://scenes/base/hud.tscn")
		var hud := hud_scn.instantiate()
		hud.name = "HUD"
		raiz.add_child(hud)

	if not raiz.has_node("UI"):
		var ui := CanvasLayer.new()
		ui.name = "UI"
		raiz.add_child(ui)
		var host := Control.new()
		host.name = "MinijuegoHost"
		host.set_anchors_preset(Control.PRESET_FULL_RECT)
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_to_group("minijuego_host")
		ui.add_child(host)
		var lbl_m := Label.new()
		lbl_m.name = "MarquitosTemporal"
		lbl_m.custom_minimum_size = Vector2(700, 60)
		lbl_m.position = Vector2(20, 560)
		lbl_m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_m.set_script(load("res://scenes/base/marquitos_temporal.gd"))
		ui.add_child(lbl_m)

	if not raiz.has_node("TurnManager"):
		var tm := Node.new()
		tm.name = "TurnManager"
		tm.set_script(load("res://scenes/base/turn_manager.gd"))
		raiz.add_child(tm)

	if not raiz.has_node("DebugTeclas"):
		var dbg := Node.new()
		dbg.name = "DebugTeclas"
		dbg.set_script(load("res://scenes/base/debug_teclas.gd"))
		raiz.add_child(dbg)

	if jugador != null and jugador.get("ui_eventos") == null:
		var capa_ui := CanvasLayer.new()
		capa_ui.name = "CapaEventosMarte"
		capa_ui.layer = 45
		jugador.add_child(capa_ui)
		var script_ev = load("res://cosdigo/eventos_marte_ui.gd")
		if script_ev != null:
			var ui_ev = script_ev.new()
			ui_ev.jugador = jugador
			jugador.set("ui_eventos", ui_ev)
			capa_ui.add_child(ui_ev)


func _on_mision_terminada_fallback(_resultado: int) -> void:
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/end/summary.tscn")

func _inicializar_estilos_globos() -> void:
	_estilo_alerta = StyleBoxTexture.new()
	_estilo_alerta.texture = TEX_GLOBO_ALERTA
	_estilo_alerta.texture_margin_left = 22.0
	_estilo_alerta.texture_margin_right = 16.0
	_estilo_alerta.texture_margin_top = 10.0
	_estilo_alerta.texture_margin_bottom = 18.0
	_estilo_alerta.content_margin_left = 16.0
	_estilo_alerta.content_margin_right = 14.0
	_estilo_alerta.content_margin_top = 8.0
	_estilo_alerta.content_margin_bottom = 16.0

	_estilo_pensamiento = StyleBoxTexture.new()
	_estilo_pensamiento.texture = TEX_GLOBO_PENSAMIENTO
	_estilo_pensamiento.texture_margin_left = 20.0
	_estilo_pensamiento.texture_margin_right = 16.0
	_estilo_pensamiento.texture_margin_top = 12.0
	_estilo_pensamiento.texture_margin_bottom = 20.0
	_estilo_pensamiento.content_margin_left = 16.0
	_estilo_pensamiento.content_margin_right = 14.0
	_estilo_pensamiento.content_margin_top = 10.0
	_estilo_pensamiento.content_margin_bottom = 18.0

	_estilo_dialogo = StyleBoxTexture.new()
	_estilo_dialogo.texture = TEX_GLOBO_DIALOGO
	_estilo_dialogo.texture_margin_left = 22.0
	_estilo_dialogo.texture_margin_right = 18.0
	_estilo_dialogo.texture_margin_top = 12.0
	_estilo_dialogo.texture_margin_bottom = 18.0
	_estilo_dialogo.content_margin_left = 18.0
	_estilo_dialogo.content_margin_right = 16.0
	_estilo_dialogo.content_margin_top = 10.0
	_estilo_dialogo.content_margin_bottom = 16.0

func _crear_globo_dialogo() -> void:
	_inicializar_estilos_globos()
	z_index = 20

	_capa_globo = CanvasLayer.new()
	_capa_globo.name = "CapaGloboMarquitos"
	_capa_globo.layer = 3
	_capa_globo.follow_viewport_enabled = true
	add_child(_capa_globo)

	_globo_panel = PanelContainer.new()
	_globo_panel.name = "GloboMarquitos"
	_globo_panel.visible = false
	_globo_panel.z_index = 100
	_globo_panel.z_as_relative = false
	_globo_panel.add_theme_stylebox_override("panel", _estilo_dialogo)

	_globo_label = Label.new()
	_globo_label.custom_minimum_size = Vector2(220, 0)
	_globo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_globo_label.add_theme_font_override("font", preload("res://fonts/SHPinscher-Regular.otf"))
	_globo_label.add_theme_font_size_override("font_size", 16)
	_globo_label.add_theme_color_override("font_color", Color(0.08, 0.10, 0.15))
	_globo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_globo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_globo_panel.add_child(_globo_label)
	_capa_globo.add_child(_globo_panel)

func _determinar_tipo_globo(texto: String) -> String:
	var t_lower := texto.to_lower()
	# 1. Alert / Alarm / Danger / Emergency / Storms
	if texto.contains("🚨") or texto.contains("⚠️") or texto.contains("🌪️") or texto.contains("🔥") \
	   or t_lower.contains("alarm") or t_lower.contains("alert") or t_lower.contains("danger") \
	   or t_lower.contains("critical") or t_lower.contains("impact") or t_lower.contains("fail") \
	   or t_lower.contains("damage") or t_lower.contains("aborted") or t_lower.contains("depleted") \
	   or t_lower.contains("leak") or t_lower.contains("breach") or t_lower.contains("storm") \
	   or t_lower.contains("warning") or t_lower.contains("alarma") or t_lower.contains("alerta") \
	   or t_lower.contains("peligro") or t_lower.contains("crítico") or t_lower.contains("critico") \
	   or t_lower.contains("impacto") or t_lower.contains("fallo") or t_lower.contains("daño"):
		return "alerta"

	# 2. Science / Thought / Curiosity / NASA Facts / Tips
	if texto.contains("💡") or texto.contains("🧠") or texto.contains("🔬") \
	   or t_lower.contains("fact") or t_lower.contains("did you know") or t_lower.contains("curiosity") \
	   or t_lower.contains("tip") or t_lower.contains("thinking") or t_lower.contains("interesting") \
	   or t_lower.contains("moxie") or t_lower.contains("kilopower") or t_lower.contains("eclss") \
	   or t_lower.contains("veggie") or t_lower.contains("recycling") or t_lower.contains("atmosphere") \
	   or t_lower.contains("radiation") or t_lower.contains("dato") or t_lower.contains("sabías"):
		return "pensamiento"

	# 3. Normal Dialogue / Sols / Meals / General
	return "dialogo"

func _hay_popup_o_minijuego() -> bool:
	var host := get_tree().get_first_node_in_group("minijuego_host")
	if host != null and host.get_child_count() > 0:
		return true
	if GameState.get("minijuego_activo") == true:
		return true
	var ui_ev = get_tree().get_first_node_in_group("eventos_ui")
	if ui_ev != null and ui_ev.get("evento_actual") != 0:
		return true
	for st in get_tree().get_nodes_in_group("estaciones"):
		if st.get("_minijuego_abierto") == true:
			return true
	return false

func _on_robot_dice(texto: String) -> void:
	if _globo_label == null or _globo_panel == null:
		return
	if texto == "":
		_globo_panel.visible = false
		_tiempo_restante_globo = 0.0
		return

	var tipo := _determinar_tipo_globo(texto)
	match tipo:
		"alerta":
			_globo_panel.add_theme_stylebox_override("panel", _estilo_alerta)
			_globo_label.add_theme_color_override("font_color", Color(0.70, 0.08, 0.08))
		"pensamiento":
			_globo_panel.add_theme_stylebox_override("panel", _estilo_pensamiento)
			_globo_label.add_theme_color_override("font_color", Color(0.08, 0.18, 0.45))
		_:
			_globo_panel.add_theme_stylebox_override("panel", _estilo_dialogo)
			_globo_label.add_theme_color_override("font_color", Color(0.08, 0.10, 0.15))

	_globo_label.text = texto
	# Duración visible: según el largo del mensaje (4.5s a 7.5s) y luego se quita automáticamente
	_tiempo_restante_globo = clampf(float(texto.length()) * 0.075, 4.5, 7.5)
	_globo_panel.visible = not _hay_popup_o_minijuego()

func _buscar_jugador() -> CharacterBody2D:
	var padre := get_parent()
	if padre == null:
		return null
	if padre is CharacterBody2D:
		return padre
	for nombre in ["Pedro", "Jugador", "CharacterBody2D", "AnimatedSprite2D"]:
		if padre.has_node(nombre) and padre.get_node(nombre) is CharacterBody2D:
			return padre.get_node(nombre)
	for child in padre.get_children():
		if child is CharacterBody2D:
			return child
	return null

func _obtener_pos_jugador() -> Vector2:
	if jugador == null:
		return global_position
	if jugador.has_method("obtener_posicion_visual"):
		return jugador.obtener_posicion_visual()
	if jugador.has_node("Animacion de pedro"):
		return jugador.get_node("Animacion de pedro").global_position
	return jugador.global_position

func _process(delta: float) -> void:
	tiempo_vuelo += delta

	if _globo_panel != null:
		if _tiempo_restante_globo > 0.0:
			_tiempo_restante_globo -= delta
			if _tiempo_restante_globo <= 0.0:
				_globo_panel.visible = false

		if _hay_popup_o_minijuego():
			_globo_panel.visible = false
		elif _tiempo_restante_globo > 0.0:
			_globo_panel.visible = true

	if jugador == null:
		jugador = _buscar_jugador()
		if jugador == null:
			return

	var pos_j: Vector2 = _obtener_pos_jugador()
	if not jugador.is_in_group("jugador") or jugador.has_node("CapaEventosMarte"):
		var pos_real := jugador.global_position + Vector2(-64.03634 * jugador.scale.x, 8.330156 * jugador.scale.y)
		if not jugador.has_method("obtener_posicion_visual"):
			pos_j = pos_real

	if jugador.velocity.x > 25.0:
		lado_actual = -1.0
		flip_h = false
	elif jugador.velocity.x < -25.0:
		lado_actual = 1.0
		flip_h = true

	var flotacion_y: float = sin(tiempo_vuelo * 4.2) * 4.5
	var flotacion_x: float = cos(tiempo_vuelo * 2.6) * 2.0

	var destino: Vector2 = pos_j + Vector2(absf(offset_lateral.x) * lado_actual + flotacion_x, offset_lateral.y + flotacion_y)
	var pos_anterior: Vector2 = global_position
	global_position = global_position.lerp(destino, clampf(velocidad_seguimiento * delta, 0.0, 1.0))

	var vel_x: float = (global_position.x - pos_anterior.x) / maxf(delta, 0.001)
	rotation = lerpf(rotation, clampf(vel_x * 0.0012, -0.18, 0.18), 8.0 * delta)

	if _globo_panel != null:
		var target_offset := Vector2(-30.0 if lado_actual > 0.0 else -190.0, -115.0)
		var destino_globo := global_position + target_offset
		if not _globo_panel.visible:
			_globo_panel.position = destino_globo
		else:
			_globo_panel.position = _globo_panel.position.lerp(destino_globo, clampf(14.0 * delta, 0.0, 1.0))
