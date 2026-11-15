extends Node
class_name TurnManager
## Dirige los 5 turnos de la misión siguiendo la guía PDF.
## Cada misión/evento aparece de uno en uno, esperando 15 segundos entre uno y otro.

const PUNTAJE_SIN_MINIJUEGO := 0.0 # sin minijuego no hay descuento de daño
const TIEMPO_ENTRE_EVENTOS := 15.0

const TEX_ICONO_ANIMO := preload("res://Fotos/Separados/Iconos/icono_animo.png")
const TEX_BOTON_BARRA := preload("res://Fotos/Separados/Iconos/boton_barra.png")

var estaciones: Dictionary = {} # id de sistema -> Station principal
var estaciones_por_id: Dictionary = {} # id de sistema -> Array[Station]

var _resuelto := false
var _puntaje_resuelto := 0.0
signal _alarma_resuelta(puntaje: float)
signal _aviso_cerrado()

func _ready() -> void:
	await get_tree().process_frame # espera a que las estaciones estén en el árbol
	_registrar_estaciones()
	GameState.mazo = EventDeck.generar(GameData.eventos, GameState.mejoras)
	_correr_partida()

func _registrar_estaciones() -> void:
	estaciones.clear()
	estaciones_por_id.clear()
	for s in get_tree().get_nodes_in_group('estaciones'):
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			estaciones[s.sistema_id] = s
			if not estaciones_por_id.has(s.sistema_id):
				estaciones_por_id[s.sistema_id] = []
			estaciones_por_id[s.sistema_id].append(s)

func _hay_minijuego_activo() -> bool:
	var host := get_tree().get_first_node_in_group('minijuego_host')
	return host != null and host.get_child_count() > 0

func _esperar_intervalo_evento(segundos: float) -> void:
	GameState.tiempo_proximo_evento = segundos
	GameState.actualizar_estado_evento(GameState.tiempo_proximo_evento, '')
	var paso := 0.25
	while GameState.tiempo_proximo_evento > 0.0 and not GameState.partida_terminada():
		await get_tree().create_timer(paso).timeout
		if GameState.partida_terminada():
			return
		# Si hay un evento climático/tornado abierto en pantalla, pausar la cuenta regresiva
		if _hay_minijuego_activo():
			continue
		GameState.tiempo_proximo_evento = maxf(0.0, GameState.tiempo_proximo_evento - paso)
		GameState.actualizar_estado_evento(GameState.tiempo_proximo_evento, '')

func _correr_partida() -> void:
	for i in GameState.TOTAL_TURNOS:
		if GameState.partida_terminada():
			return
		GameState.empezar_turno()
		var restantes := GameState.TOTAL_TURNOS - GameState.turno
		GameState.decir("Sol %d of %d initiated (%d sols remaining after this)." % [
			GameState.turno, GameState.TOTAL_TURNOS, restantes
		])
		await get_tree().create_timer(5.0).timeout
		if GameState.partida_terminada():
			return
		await _ofrecer_menu_del_dia()
		if GameState.partida_terminada():
			return
		await _esperar_intervalo_evento(TIEMPO_ENTRE_EVENTOS)
		if GameState.partida_terminada():
			return
		_registrar_estaciones()
		var evento := GameState.resolver_variante(GameState.mazo[i])
		await _jugar_evento(evento)
		if GameState.partida_terminada():
			return
		await get_tree().create_timer(1.5).timeout
		GameState.terminar_turno()
		if GameState.partida_terminada():
			return

func _jugar_evento(evento: Dictionary) -> void:
	var sis_id: String = evento.get('estacion', evento.get('sistema', ''))
	var info_sis: Dictionary = GameData.sistemas.get(sis_id, {})
	var nombre_sis: String = info_sis.get('nombre', sis_id.capitalize())
	var nombre_ev: String = evento.get('nombre', 'Incident')
	var aviso_ev: String = evento.get('aviso', '')

	GameState.decir("🚨 ALERT IN %s! %s" % [nombre_sis.to_upper(), aviso_ev])
	var puntaje := PUNTAJE_SIN_MINIJUEGO
	var lista: Array = estaciones_por_id.get(sis_id, [])

	if not lista.is_empty() and evento.get('minijuego', 'ninguno') != 'ninguno':
		GameState.actualizar_estado_evento(0.0, "🚨 %s — Go to %s module and press [E]" % [nombre_ev, nombre_sis])
		_resuelto = false
		_puntaje_resuelto = 0.0
		var cb := func(p: float) -> void:
			if not _resuelto:
				_resuelto = true
				_puntaje_resuelto = p
				_alarma_resuelta.emit(p)
		for st in lista:
			if is_instance_valid(st):
				st.minijuego_terminado.connect(cb, CONNECT_ONE_SHOT)
				st.activar_alarma(evento)
		puntaje = await _alarma_resuelta
		for st in lista:
			if is_instance_valid(st) and st.has_method('cancelar_alarma_externa'):
				st.cancelar_alarma_externa()
	else:
		# Evento automático del turno (sin minijuego de estación): suena alarma y muestra tarjeta de aviso
		GameState.sonar_alarma('estacion')
		GameState.actualizar_estado_evento(0.0, "📢 %s (%s)" % [nombre_ev, nombre_sis])
		await _mostrar_tarjeta_evento_automatico(evento, nombre_sis)

	GameState.aplicar_evento(evento, puntaje)
	GameState.decir("💡 Dato NASA: " + evento.get('dato', ''))
	GameState.actualizar_estado_evento(TIEMPO_ENTRE_EVENTOS, '')

func _obtener_textura_comida(opc: Dictionary) -> Texture2D:
	var ruta_img: String = opc.get('imagen', '')
	if ruta_img != "" and ResourceLoader.exists(ruta_img):
		return load(ruta_img)
	
	var id_c: String = opc.get('id', '').to_lower()
	var nom_c: String = opc.get('nombre', '').to_lower()
	
	if 'ensalada' in id_c or 'ensalada' in nom_c or 'veggie' in nom_c or 'cultivo' in nom_c:
		if ResourceLoader.exists("res://comida/salad.png"):
			return load("res://comida/salad.png")
	elif 'ravioli' in id_c or 'ravioli' in nom_c:
		if ResourceLoader.exists("res://comida/ravioli.png"):
			return load("res://comida/ravioli.png")
	elif 'pavo' in id_c or 'pavo' in nom_c:
		if ResourceLoader.exists("res://comida/pavo.png"):
			return load("res://comida/pavo.png")
	elif 'sopa' in id_c or 'sopa' in nom_c or 'soup' in id_c or 'caldo' in nom_c:
		if ResourceLoader.exists("res://comida/soup.png"):
			return load("res://comida/soup.png")
	elif 'avena' in id_c or 'avena' in nom_c:
		if ResourceLoader.exists("res://comida/avena.png"):
			return load("res://comida/avena.png")
	elif 'pollo' in id_c or 'pollo' in nom_c:
		if ResourceLoader.exists("res://comida/arroz con pollo.png"):
			return load("res://comida/arroz con pollo.png")
	elif 'fruto' in id_c or 'fruto' in nom_c or 'seco' in id_c or 'nuez' in nom_c:
		if ResourceLoader.exists("res://comida/fruto seco.png"):
			return load("res://comida/fruto seco.png")
	elif 'pasta' in id_c or 'pasta' in nom_c or 'fideo' in nom_c:
		if ResourceLoader.exists("res://comida/pasta.png"):
			return load("res://comida/pasta.png")
	elif 'huevo' in id_c or 'egg' in id_c or 'huevo' in nom_c or 'omelette' in nom_c:
		if ResourceLoader.exists("res://comida/eggs.png"):
			return load("res://comida/eggs.png")
	elif 'frijol' in id_c or 'frijol' in nom_c or 'tortilla' in nom_c or 'burrito' in nom_c:
		if ResourceLoader.exists("res://comida/arroz con frijoles.png"):
			return load("res://comida/arroz con frijoles.png")
	elif 'arroz' in id_c or 'arroz' in nom_c or 'curry' in nom_c or 'salmon' in nom_c:
		if ResourceLoader.exists("res://comida/rice.png"):
			return load("res://comida/rice.png")
	
	if ResourceLoader.exists("res://comida/rice.png"):
		return load("res://comida/rice.png")
	return null

func _mostrar_tarjeta_evento_automatico(evento: Dictionary, nombre_sis: String) -> void:
	var host := get_tree().get_first_node_in_group('minijuego_host')
	if host == null:
		await get_tree().create_timer(3.0).timeout
		return

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.04, 0.08, 0.65)
	host.add_child(fondo)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 270)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-280, -135)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.09, 0.13, 0.20, 0.97)
	estilo.border_color = Color(1.0, 0.78, 0.25)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 18
	estilo.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", estilo)
	fondo.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var lbl_tit := Label.new()
	lbl_tit.text = "📢 EVENTO DEL TURNO %d: %s" % [GameState.turno, evento.get('nombre', 'Evento').to_upper()]
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_tit.add_theme_font_size_override("font_size", 18)
	lbl_tit.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	vbox.add_child(lbl_tit)

	var lbl_sis := Label.new()
	lbl_sis.text = "Sistema involucrado: %s (%s)" % [nombre_sis, GameState.nivel(evento.get('sistema', 'energia')).capitalize()]
	lbl_sis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sis.add_theme_font_size_override("font_size", 14)
	lbl_sis.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	vbox.add_child(lbl_sis)

	if evento.get('sistema', '') == 'alimentos':
		var tex_ev := TextureRect.new()
		tex_ev.custom_minimum_size = Vector2(0, 65)
		tex_ev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_ev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_ev.texture = _obtener_textura_comida(evento)
		vbox.add_child(tex_ev)

	var lbl_aviso := Label.new()
	lbl_aviso.text = "%s\n\n💡 %s" % [evento.get('aviso', ''), evento.get('dato', '')]
	lbl_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_aviso.add_theme_font_size_override("font_size", 14)
	lbl_aviso.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	vbox.add_child(lbl_aviso)

	var btn := Button.new()
	btn.text = "Entendido — Continuar misión"
	btn.custom_minimum_size = Vector2(240, 38)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)

	var cerrado := [false]
	var cerrar_fn := func() -> void:
		if not cerrado[0]:
			cerrado[0] = true
			if is_instance_valid(fondo):
				fondo.queue_free()
			_aviso_cerrado.emit()

	btn.pressed.connect(cerrar_fn)
	get_tree().create_timer(6.0).timeout.connect(cerrar_fn)
	await _aviso_cerrado

func _ofrecer_menu_del_dia() -> void:
	var host := get_tree().get_first_node_in_group('minijuego_host')
	if host == null:
		return

	var lista_comidas: Array = GameData.alimentos.duplicate()
	if lista_comidas.is_empty():
		return

	var opciones: Array = []
	for a in lista_comidas:
		if a.get('requiere_mejora', '') != '':
			if GameState.esta_mejorado(a['requiere_mejora']):
				opciones.append(a)
		else:
			opciones.append(a)

	# Identificar imágenes consumidas previamente para priorizar platos con imágenes no vistas
	var imagenes_consumidas: Array = []
	for c in GameState.comidas:
		var id_c: String = c.get('id', '') if typeof(c) == TYPE_DICTIONARY else str(c)
		for a in lista_comidas:
			if a.get('id', '') == id_c:
				var img: String = a.get('imagen', '')
				if img != "" and not (img in imagenes_consumidas):
					imagenes_consumidas.append(img)
				break

	var nuevas: Array = []
	var repetidas: Array = []
	for opc in opciones:
		var img: String = opc.get('imagen', '')
		if img != "" and (img in imagenes_consumidas):
			repetidas.append(opc)
		else:
			nuevas.append(opc)

	nuevas.shuffle()
	repetidas.shuffle()
	var pool: Array = nuevas + repetidas

	# Garantizar que ninguna de las 3 opciones tenga la misma imagen ni el mismo ID
	var disponibles: Array = []
	var imagenes_en_menu: Array = []
	var ids_en_menu: Array = []
	for opc in pool:
		var img: String = opc.get('imagen', '')
		var id_o: String = opc.get('id', '')
		if not (img in imagenes_en_menu) and not (id_o in ids_en_menu):
			disponibles.append(opc)
			if img != "":
				imagenes_en_menu.append(img)
			ids_en_menu.append(id_o)
		if disponibles.size() >= 3:
			break

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.04, 0.08, 0.85)
	host.add_child(fondo)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 440)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.12, 0.18, 0.98)
	estilo.border_color = Color(0.4, 0.9, 0.5)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 20
	estilo.content_margin_right = 20
	estilo.content_margin_top = 16
	estilo.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", estilo)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var lbl_tit := Label.new()
	lbl_tit.text = "🍽️ SOL %d NUTRITION — ASTRONAUT DAILY RATIONS" % GameState.turno
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_font_size_override("font_size", 17)
	lbl_tit.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	vbox.add_child(lbl_tit)

	var lbl_sub := Label.new()
	lbl_sub.text = "Select your daily ration. Varying the menu and consuming fresh crops maintains high crew morale."
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(lbl_sub)

	var hbox_opc := HBoxContainer.new()
	hbox_opc.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_opc.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_opc)

	var cerrado := [false]
	var cerrar_fn := func(id_elegido: String) -> void:
		if not cerrado[0]:
			cerrado[0] = true
			GameState.registrar_comida(id_elegido)
			if is_instance_valid(fondo):
				fondo.queue_free()

	for opc in disponibles:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(230, 295)
		btn.focus_mode = Control.FOCUS_NONE

		var st_norm := StyleBoxFlat.new()
		st_norm.bg_color = Color(0.10, 0.14, 0.22, 0.95)
		st_norm.border_color = Color(0.28, 0.45, 0.65, 0.85)
		st_norm.set_border_width_all(2)
		st_norm.set_corner_radius_all(10)
		st_norm.content_margin_left = 12
		st_norm.content_margin_right = 12
		st_norm.content_margin_top = 10
		st_norm.content_margin_bottom = 10
		btn.add_theme_stylebox_override("normal", st_norm)

		var st_hover := StyleBoxFlat.new()
		st_hover.bg_color = Color(0.14, 0.20, 0.32, 0.98)
		st_hover.border_color = Color(0.45, 0.95, 0.65)
		st_hover.set_border_width_all(2)
		st_hover.set_corner_radius_all(10)
		st_hover.content_margin_left = 12
		st_hover.content_margin_right = 12
		st_hover.content_margin_top = 10
		st_hover.content_margin_bottom = 10
		btn.add_theme_stylebox_override("hover", st_hover)

		var st_pressed := StyleBoxFlat.new()
		st_pressed.bg_color = Color(0.08, 0.12, 0.18, 1.0)
		st_pressed.border_color = Color(0.3, 0.8, 0.5)
		st_pressed.set_border_width_all(2)
		st_pressed.set_corner_radius_all(10)
		st_pressed.content_margin_left = 12
		st_pressed.content_margin_right = 12
		st_pressed.content_margin_top = 10
		st_pressed.content_margin_bottom = 10
		btn.add_theme_stylebox_override("pressed", st_pressed)

		var card_vbox := VBoxContainer.new()
		card_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_theme_constant_override("separation", 5)
		btn.add_child(card_vbox)

		# Imagen de la comida (de res://comida/)
		var panel_img := PanelContainer.new()
		panel_img.custom_minimum_size = Vector2(0, 110)
		panel_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_img := StyleBoxFlat.new()
		st_img.bg_color = Color(0.05, 0.07, 0.12, 0.85)
		st_img.border_color = Color(0.25, 0.35, 0.50, 0.6)
		st_img.set_border_width_all(1)
		st_img.set_corner_radius_all(8)
		panel_img.add_theme_stylebox_override("panel", st_img)

		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(0, 100)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.texture = _obtener_textura_comida(opc)
		panel_img.add_child(tex_rect)
		card_vbox.add_child(panel_img)

		# Título
		var lbl_nom := Label.new()
		lbl_nom.text = opc.get('nombre', '')
		lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_nom.add_theme_font_size_override("font_size", 13)
		lbl_nom.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		lbl_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(lbl_nom)

		# Categoría y Tipo
		var lbl_tipo := Label.new()
		lbl_tipo.text = "[ %s ]" % opc.get('tipo', '')
		lbl_tipo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_tipo.add_theme_font_size_override("font_size", 11)
		lbl_tipo.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
		lbl_tipo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(lbl_tipo)

		# Descripción
		var lbl_desc := Label.new()
		lbl_desc.text = opc.get('descripcion', '')
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_desc.add_theme_font_size_override("font_size", 10)
		lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
		lbl_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(lbl_desc)

		# Morale boost
		var extra_fresco := 3 if (GameState.esta_mejorado('alimentos') and opc.get('tipo', '') == 'Fresh Local Harvest') else 0
		var boost: int = int(opc.get('animo_base', 3)) + extra_fresco

		var hbox_animo := HBoxContainer.new()
		hbox_animo.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox_animo.add_theme_constant_override("separation", 6)
		hbox_animo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(hbox_animo)

		var ic_animo := TextureRect.new()
		ic_animo.custom_minimum_size = Vector2(20, 20)
		ic_animo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic_animo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic_animo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic_animo.texture = TEX_ICONO_ANIMO
		hbox_animo.add_child(ic_animo)

		var lbl_animo := Label.new()
		lbl_animo.text = "Morale: +%d%%" % boost
		lbl_animo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_animo.add_theme_font_size_override("font_size", 11)
		lbl_animo.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		lbl_animo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_animo.add_child(lbl_animo)

		var pill_btn := PanelContainer.new()
		pill_btn.custom_minimum_size = Vector2(160, 26)
		pill_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_pill := StyleBoxTexture.new()
		sb_pill.texture = TEX_BOTON_BARRA
		sb_pill.texture_margin_left = 6.0
		sb_pill.texture_margin_right = 6.0
		sb_pill.texture_margin_top = 2.0
		sb_pill.texture_margin_bottom = 2.0
		sb_pill.modulate_color = Color(0.2, 0.7, 0.4, 0.9)
		pill_btn.add_theme_stylebox_override("panel", sb_pill)

		var lbl_consumir := Label.new()
		lbl_consumir.text = "🍽️ Select Ration"
		lbl_consumir.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_consumir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_consumir.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_consumir.add_theme_font_size_override("font_size", 11)
		lbl_consumir.add_theme_color_override("font_color", Color.WHITE)
		lbl_consumir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill_btn.add_child(lbl_consumir)
		card_vbox.add_child(pill_btn)

		btn.pressed.connect(func(): if SoundManager != null: SoundManager.play_select())
		btn.pressed.connect(cerrar_fn.bind(opc.get('id', '')))
		hbox_opc.add_child(btn)

	var lbl_timer := Label.new()
	lbl_timer.text = "⏳ Select your daily ration (or auto-selected in 14 seconds)"
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.add_theme_font_size_override("font_size", 11)
	lbl_timer.add_theme_color_override("font_color", Color(0.70, 0.85, 0.95))
	vbox.add_child(lbl_timer)

	get_tree().create_timer(14.0).timeout.connect(func():
		if not cerrado[0] and not disponibles.is_empty():
			cerrar_fn.call(disponibles[0].get('id', ''))
	)

	while not cerrado[0] and not GameState.partida_terminada():
		await get_tree().process_frame
