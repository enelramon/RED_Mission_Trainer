extends Minijuego
## Minijuego interactivo centrado en pantalla para barra_zona, secuencia y cables.

var _datos: Dictionary = {}
var _tipo: String = 'barra_zona'
var _progreso_barra: float = 0.0
var _dir_barra: float = 1.0
var _barra_activa: bool = false
var _slider_barra: ProgressBar = null
var _lbl_estado: Label = null

var _paso_secuencia: int = 0
var _botones_secuencia: Array[Button] = []

var _cables_conectados: int = 0
var _total_cables: int = 4

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func iniciar(datos_evento: Dictionary) -> void:
	_datos = datos_evento
	_tipo = datos_evento.get('minijuego', 'barra_zona')
	if name == 'Secuencia':
		_tipo = 'secuencia'
	elif name == 'Cables':
		_tipo = 'cables'
	elif name == 'BarraZona':
		_tipo = 'barra_zona'
	_construir_interfaz()

func _construir_interfaz() -> void:
	for c in get_children():
		c.queue_free()

	# Fondo oscuro semitransparente
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.03, 0.05, 0.09, 0.82)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 340)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.14, 0.22, 0.98)
	sb.border_color = Color(0.30, 0.75, 1.0, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	centro.add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	panel.add_child(caja)

	var titulo := Label.new()
	titulo.text = "🔧 " + str(_datos.get('nombre', 'Habitat Station'))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 20)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	caja.add_child(titulo)

	var desc := Label.new()
	desc.text = str(_datos.get('aviso', 'Calibrate the system to protect the habitat.'))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	caja.add_child(desc)

	_lbl_estado = Label.new()
	_lbl_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_estado.add_theme_font_size_override("font_size", 15)
	_lbl_estado.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
	caja.add_child(_lbl_estado)

	if _tipo == 'secuencia':
		_armar_secuencia(caja)
	elif _tipo == 'cables':
		_armar_cables(caja)
	else:
		_armar_barra_zona(caja)

	var sep := HSeparator.new()
	caja.add_child(sep)

	var fila_abajo := HBoxContainer.new()
	fila_abajo.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_abajo.add_theme_constant_override("separation", 16)
	caja.add_child(fila_abajo)

	var btn_rapido := Button.new()
	btn_rapido.text = "✓ Automated Repair (85%)"
	btn_rapido.custom_minimum_size = Vector2(220, 36)
	btn_rapido.pressed.connect(func(): finalizar(0.85))
	fila_abajo.add_child(btn_rapido)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "✕ Abort / Exit (0%)"
	btn_cerrar.custom_minimum_size = Vector2(120, 36)
	btn_cerrar.pressed.connect(func(): finalizar(0.0))
	fila_abajo.add_child(btn_cerrar)

func _armar_barra_zona(caja: VBoxContainer) -> void:
	_barra_activa = true
	_lbl_estado.text = "Stop the indicator near the center (40% - 75%) with [SPACE] or click:"

	_slider_barra = ProgressBar.new()
	_slider_barra.min_value = 0.0
	_slider_barra.max_value = 100.0
	_slider_barra.value = 50.0
	_slider_barra.custom_minimum_size = Vector2(440, 32)
	caja.add_child(_slider_barra)

	var btn_fijar := Button.new()
	btn_fijar.text = "⚡ LOCK CALIBRATION NOW! [SPACE]"
	btn_fijar.custom_minimum_size = Vector2(320, 44)
	btn_fijar.pressed.connect(_detener_barra)
	caja.add_child(btn_fijar)

func _detener_barra() -> void:
	if not _barra_activa:
		return
	_barra_activa = false
	var dist_centro := absf(_progreso_barra - 55.0)
	var puntaje := clampf(1.0 - (dist_centro / 55.0), 0.25, 1.0)
	if dist_centro <= 18.0:
		puntaje = 1.0
	finalizar(puntaje)

func _armar_secuencia(caja: VBoxContainer) -> void:
	_paso_secuencia = 0
	_botones_secuencia.clear()
	_lbl_estado.text = "Activate modules in sequence from 1 to 4:"

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)

	var nombres := ["1. Filter", "2. Valve", "3. Purge", "4. Seal"]
	for i in range(4):
		var b := Button.new()
		b.text = nombres[i]
		b.custom_minimum_size = Vector2(105, 52)
		b.disabled = (i != 0)
		var idx := i
		b.pressed.connect(func(): _pulsar_secuencia(idx))
		fila.add_child(b)
		_botones_secuencia.append(b)

func _pulsar_secuencia(idx: int) -> void:
	if idx == _paso_secuencia:
		_botones_secuencia[idx].disabled = true
		_botones_secuencia[idx].text = "✓ OK"
		_paso_secuencia += 1
		if _paso_secuencia < _botones_secuencia.size():
			_botones_secuencia[_paso_secuencia].disabled = false
			_lbl_estado.text = "Good! Now activate step %d of 4:" % (_paso_secuencia + 1)
		else:
			finalizar(1.0)

func _armar_cables(caja: VBoxContainer) -> void:
	_cables_conectados = 0
	_total_cables = 4
	_lbl_estado.text = "Click all 4 conduits/cables to seal them (0 / 4):"

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	caja.add_child(grid)

	var etiquetas := ["🔌 Conduit A", "🔌 Conduit B", "🔌 Conduit C", "🔌 Conduit D"]
	for i in range(4):
		var b := Button.new()
		b.text = etiquetas[i] + " [Connect]"
		b.custom_minimum_size = Vector2(220, 44)
		b.pressed.connect(func():
			b.disabled = true
			b.text = etiquetas[i] + " [✓ SEALED]"
			_cables_conectados += 1
			_lbl_estado.text = "Conduits sealed: %d / %d" % [_cables_conectados, _total_cables]
			if _cables_conectados >= _total_cables:
				finalizar(1.0)
		)
		grid.add_child(b)

func _process(delta: float) -> void:
	if _barra_activa and _slider_barra != null:
		_progreso_barra += _dir_barra * delta * 95.0
		if _progreso_barra >= 100.0:
			_progreso_barra = 100.0
			_dir_barra = -1.0
		elif _progreso_barra <= 0.0:
			_progreso_barra = 0.0
			_dir_barra = 1.0
		_slider_barra.value = _progreso_barra

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _barra_activa and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			get_viewport().set_input_as_handled()
			_detener_barra()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			finalizar(0.0)
