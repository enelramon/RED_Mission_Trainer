extends CanvasLayer
## Solo escucha; nunca modifica recursos. Muestra las barras de recursos con iconos y el panel de turnos.

@onready var barras := {
	'energia': %BarraEnergia, 'aire': %BarraAire, 'agua': %BarraAgua,
	'alimentos': %BarraAlimentos, 'proteccion': %BarraProteccion,
}

const ICONOS_TEXTURAS := {
	'energia': preload("res://Fotos/Separados/Iconos/icono_energia.png"),
	'aire': preload("res://Fotos/Separados/Iconos/icono_aire.png"),
	'agua': preload("res://Fotos/Separados/Iconos/icono_agua.png"),
	'alimentos': preload("res://Fotos/Separados/Iconos/icono_alimentos.png"),
	'proteccion': preload("res://Fotos/Separados/Iconos/icono_proteccion.png"),
	'animo': preload("res://Fotos/Separados/Iconos/icono_animo.png"),
}

const TEX_BOTON_BARRA := preload("res://Fotos/Separados/Iconos/boton_barra.png")

const COLORES_BARRAS := {
	'energia': Color(0.96, 0.80, 0.20),
	'aire': Color(0.35, 0.85, 1.0),
	'agua': Color(0.25, 0.65, 1.0),
	'alimentos': Color(0.35, 0.90, 0.40),
	'proteccion': Color(0.95, 0.38, 0.32),
	'animo': Color(0.85, 0.50, 0.95),
}

const NOMBRES_BARRAS := {
	'energia': 'Energy',
	'aire': 'Oxygen',
	'agua': 'Water',
	'alimentos': 'Food',
	'proteccion': 'Shielding',
	'animo': 'Morale',
}

var _etiquetas_barra: Dictionary = {}
var _lbl_turno_titulo: Label = null
var _lbl_turno_sub: Label = null
var _lbl_evento_estado: Label = null
var _insignias_turno: Array[Label] = []

func _ready() -> void:
	if has_node("Barras"):
		$Barras.position = Vector2(14, 12)
		$Barras.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Barras.add_theme_constant_override("separation", 6)

	var orden_base := ['energia', 'aire', 'agua', 'alimentos', 'proteccion']
	for id in orden_base:
		if not barras.has(id):
			continue
		var b: ProgressBar = barras[id]
		if b.get_parent() == $Barras:
			$Barras.remove_child(b)

		var fila := HBoxContainer.new()
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_theme_constant_override("separation", 6)
		$Barras.add_child(fila)

		var icono := TextureRect.new()
		icono.custom_minimum_size = Vector2(26, 26)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono.texture = ICONOS_TEXTURAS.get(id)
		fila.add_child(icono)

		b.custom_minimum_size = Vector2(200, 24)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.value = GameState.recursos.get(id, 100.0)

		var bg_sb := StyleBoxTexture.new()
		bg_sb.texture = TEX_BOTON_BARRA
		bg_sb.texture_margin_left = 6.0
		bg_sb.texture_margin_right = 6.0
		bg_sb.texture_margin_top = 2.0
		bg_sb.texture_margin_bottom = 2.0
		b.add_theme_stylebox_override("background", bg_sb)

		var fill_sb := StyleBoxFlat.new()
		fill_sb.bg_color = COLORES_BARRAS.get(id, Color.WHITE)
		fill_sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override("fill", fill_sb)

		var lbl := Label.new()
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lbl)
		_etiquetas_barra[id] = lbl

		fila.add_child(b)
		_actualizar_texto_barra(id, b.value)

	# Fila para el Ánimo / Moral de la tripulación
	if not barras.has('animo') and has_node("Barras"):
		var fila_animo := HBoxContainer.new()
		fila_animo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila_animo.add_theme_constant_override("separation", 6)
		$Barras.add_child(fila_animo)

		var icono_animo := TextureRect.new()
		icono_animo.custom_minimum_size = Vector2(26, 26)
		icono_animo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono_animo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono_animo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono_animo.texture = ICONOS_TEXTURAS['animo']
		fila_animo.add_child(icono_animo)

		var b_a := ProgressBar.new()
		b_a.name = "BarraAnimo"
		b_a.custom_minimum_size = Vector2(200, 24)
		b_a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b_a.show_percentage = false
		b_a.value = GameState.recursos.get('animo', 100.0)

		var bg_sb_a := StyleBoxTexture.new()
		bg_sb_a.texture = TEX_BOTON_BARRA
		bg_sb_a.texture_margin_left = 6.0
		bg_sb_a.texture_margin_right = 6.0
		bg_sb_a.texture_margin_top = 2.0
		bg_sb_a.texture_margin_bottom = 2.0
		b_a.add_theme_stylebox_override("background", bg_sb_a)

		var fill_sb_a := StyleBoxFlat.new()
		fill_sb_a.bg_color = COLORES_BARRAS['animo']
		fill_sb_a.set_corner_radius_all(3)
		b_a.add_theme_stylebox_override("fill", fill_sb_a)

		var lbl_a := Label.new()
		lbl_a.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_a.add_theme_font_size_override("font_size", 12)
		lbl_a.add_theme_color_override("font_color", Color.WHITE)
		lbl_a.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		lbl_a.add_theme_constant_override("outline_size", 4)
		lbl_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b_a.add_child(lbl_a)

		fila_animo.add_child(b_a)
		barras['animo'] = b_a
		_etiquetas_barra['animo'] = lbl_a
		_actualizar_texto_barra('animo', b_a.value)

	_crear_panel_turnos()

	GameState.recurso_cambio.connect(_on_recurso_cambio)
	GameState.turno_cambio.connect(_on_turno_cambio)
	if GameState.has_signal("estado_evento_cambio"):
		GameState.estado_evento_cambio.connect(_actualizar_panel_turnos)
	_actualizar_panel_turnos()

func _crear_panel_turnos() -> void:
	var panel := PanelContainer.new()
	panel.name = "PanelTurnos"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-240, 10)
	panel.custom_minimum_size = Vector2(480, 88)

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.09, 0.15, 0.90)
	estilo.border_color = Color(0.35, 0.75, 1.0, 0.85)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", estilo)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_lbl_turno_titulo = Label.new()
	_lbl_turno_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_turno_titulo.add_theme_font_size_override("font_size", 15)
	_lbl_turno_titulo.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	_lbl_turno_titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_lbl_turno_titulo.add_theme_constant_override("outline_size", 4)
	vbox.add_child(_lbl_turno_titulo)

	var hbox_pasos := HBoxContainer.new()
	hbox_pasos.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_pasos.add_theme_constant_override("separation", 8)
	hbox_pasos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hbox_pasos)

	_insignias_turno.clear()
	for i in range(1, GameState.TOTAL_TURNOS + 1):
		var badge := Label.new()
		badge.text = "[ Sol %d ]" % i
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		badge.add_theme_constant_override("outline_size", 3)
		hbox_pasos.add_child(badge)
		_insignias_turno.append(badge)

	_lbl_evento_estado = Label.new()
	_lbl_evento_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_evento_estado.add_theme_font_size_override("font_size", 13)
	_lbl_evento_estado.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	_lbl_evento_estado.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_lbl_evento_estado.add_theme_constant_override("outline_size", 4)
	vbox.add_child(_lbl_evento_estado)

func _actualizar_panel_turnos() -> void:
	var t_actual := maxi(1, GameState.turno)
	var total := GameState.TOTAL_TURNOS
	var quedan := maxi(0, total - t_actual)

	if _lbl_turno_titulo != null:
		if quedan == 0:
			_lbl_turno_titulo.text = "🗓️ SOL %d OF %d  —  Final mission sol!" % [t_actual, total]
		elif quedan == 1:
			_lbl_turno_titulo.text = "🗓️ SOL %d OF %d  —  1 sol remaining after this" % [t_actual, total]
		else:
			_lbl_turno_titulo.text = "🗓️ SOL %d OF %d  —  %d sols remaining after this" % [t_actual, total, quedan]

	for idx in _insignias_turno.size():
		var num := idx + 1
		var badge: Label = _insignias_turno[idx]
		if num < t_actual:
			badge.text = "[✓ S%d]" % num
			badge.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
		elif num == t_actual:
			badge.text = "[▶ SOL %d]" % num
			badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
		else:
			badge.text = "[ S%d ]" % num
			badge.add_theme_color_override("font_color", Color(0.62, 0.70, 0.80))

	if _lbl_evento_estado != null:
		if GameState.evento_en_curso != "":
			_lbl_evento_estado.text = GameState.evento_en_curso
			_lbl_evento_estado.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		else:
			var segs := int(ceil(GameState.tiempo_proximo_evento))
			_lbl_evento_estado.text = "⏳ Next incident in: %d s   (1 alert at a time)" % segs
			_lbl_evento_estado.add_theme_color_override("font_color", Color(0.72, 0.95, 1.0))

func _actualizar_texto_barra(id: String, valor: float) -> void:
	if _etiquetas_barra.has(id):
		_etiquetas_barra[id].text = "%s: %d%%" % [NOMBRES_BARRAS.get(id, id), int(round(valor))]

func _on_turno_cambio(_numero: int) -> void:
	_actualizar_panel_turnos()

func _on_recurso_cambio(id: String, valor: float, _delta: float, _motivo: String) -> void:
	if barras.has(id):
		create_tween().tween_property(barras[id], 'value', valor, 0.4)
		_actualizar_texto_barra(id, valor)
