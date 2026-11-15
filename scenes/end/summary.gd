extends Control
## Pantalla de Resumen Final de la Misión (evaluación 100% en base a porcentajes de recursos).
## Los minijuegos de estación reducen el porcentaje (%) de daño sufrido por los sistemas.

const DATOS_CURIOSOS_MARTE := [
	"🔬 NASA MOXIE on Mars: The MOXIE instrument produced breathable oxygen by converting atmospheric CO₂ at 800 °C with 98% purity.",
	"⚡ Kilopower vs Dust: NASA's fission reactors are designed to operate at constant 100% power without losing output during global dust storms.",
	"💧 ECLSS Recycling: On Mars missions, cutting-edge brine processors recover up to 98% of crew wastewater.",
	"🛡️ Shields & Regolith: A 1-to-2-meter layer of regolith or ice over the habitat blocks over 90% of cosmic radiation and solar flares.",
	"🌱 Closed-Loop Crops: Microalgae bioreactors and fresh crops provide up to 25% of fresh diet and sustain astronaut morale.",
	"🌪️ Martian Dust Devils: Atmospheric pressure on Mars is only ~1% of Earth's, so vortices have weak mechanical force but carry electrostatically charged dust."
]

const ICONOS_SISTEMAS := {
	'energia': '⚡',
	'aire': '💨',
	'agua': '💧',
	'alimentos': '🌱',
	'proteccion': '🛡️',
	'animo': '🧠'
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

func _ready() -> void:
	var r: Dictionary = GameState.resumen()
	var abortada: bool = (r.get('resultado', GameState.Resultado.COMPLETADA) == GameState.Resultado.ABORTADA)

	# Mantener compatibilidad con los nodos base de summary.tscn
	if has_node("Titulo"):
		$Titulo.visible = false
	if has_node("Causa"):
		$Causa.visible = false
	if has_node("BotonReiniciar"):
		$BotonReiniciar.visible = false
		if not $BotonReiniciar.pressed.is_connected(_on_reiniciar):
			$BotonReiniciar.pressed.connect(_on_reiniciar)

	_construir_interfaz_resumen(r, abortada)

func _construir_interfaz_resumen(r: Dictionary, abortada: bool) -> void:
	var rec_finales: Dictionary = r.get('recursos_finales', {})
	var suma_pct := 0.0
	var total_vitales := 0
	for id_v in ['energia', 'aire', 'agua', 'alimentos', 'proteccion']:
		if rec_finales.has(id_v):
			suma_pct += float(rec_finales[id_v])
			total_vitales += 1
	var promedio_pct := (suma_pct / float(maxi(1, total_vitales)))

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.04, 0.06, 0.10, 1.0)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 16)
	add_child(margen)

	var vbox_raiz := VBoxContainer.new()
	vbox_raiz.add_theme_constant_override("separation", 12)
	margen.add_child(vbox_raiz)

	# --- ENCABEZADO BASADO EN % ---
	var panel_header := _crear_panel(
		Color(0.18, 0.07, 0.08, 0.96) if abortada else Color(0.07, 0.15, 0.12, 0.96),
		Color(1.0, 0.35, 0.35) if abortada else Color(0.35, 0.95, 0.55)
	)
	vbox_raiz.add_child(panel_header)

	var vbox_header := VBoxContainer.new()
	vbox_header.add_theme_constant_override("separation", 4)
	panel_header.add_child(vbox_header)

	var lbl_titulo := Label.new()
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 24)
	if abortada:
		var id_causa: String = r.get('causa_aborto', '')
		var nom_causa: String = GameData.sistemas.get(id_causa, {}).get('nombre', id_causa.capitalize())
		lbl_titulo.text = "⚠️ MISSION ABORTED — %s REACHED 0%%" % nom_causa.to_upper()
		lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		if has_node("Titulo"):
			$Titulo.text = "Mission Aborted"
		if has_node("Causa"):
			$Causa.text = "Depleted: " + nom_causa
	else:
		lbl_titulo.text = "🚀 MISSION SUCCESSFUL — AVERAGE SURVIVAL: %d%%" % int(round(promedio_pct))
		lbl_titulo.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
		if has_node("Titulo"):
			$Titulo.text = "Mission Completed"
		if has_node("Causa"):
			$Causa.text = "Completed all 5 Sols."
	vbox_header.add_child(lbl_titulo)

	var lbl_calificacion := Label.new()
	lbl_calificacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_calificacion.add_theme_font_size_override("font_size", 14)
	if abortada:
		lbl_calificacion.text = "Diagnosis: Habitat collapse due to depleted critical resource (0%). Emergency crew evacuation."
		lbl_calificacion.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8))
	elif promedio_pct >= 80.0:
		lbl_calificacion.text = "Diagnosis: OPTIMAL HABITAT (%d%% remaining avg) — Outstanding resource conservation." % int(round(promedio_pct))
		lbl_calificacion.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))
	elif promedio_pct >= 55.0:
		lbl_calificacion.text = "Diagnosis: OPERATIONAL HABITAT (%d%% remaining avg) — Colony endured with moderate reserves." % int(round(promedio_pct))
		lbl_calificacion.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	else:
		lbl_calificacion.text = "Diagnosis: CRITICAL HABITAT (%d%% remaining avg) — Colony barely survived near critical margins." % int(round(promedio_pct))
		lbl_calificacion.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4))
	vbox_header.add_child(lbl_calificacion)

	# --- CUERPO EN DOS COLUMNAS ---
	var hbox_cuerpo := HBoxContainer.new()
	hbox_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_cuerpo.add_theme_constant_override("separation", 16)
	vbox_raiz.add_child(hbox_cuerpo)

	# Columna Izquierda: Porcentajes finales por sistema
	var panel_izq := _crear_panel(Color(0.08, 0.11, 0.18, 0.95), Color(0.3, 0.65, 0.95))
	panel_izq.custom_minimum_size = Vector2(400, 0)
	panel_izq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_cuerpo.add_child(panel_izq)

	var scroll_izq := ScrollContainer.new()
	scroll_izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_izq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_izq.add_child(scroll_izq)

	var vbox_izq := VBoxContainer.new()
	vbox_izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_izq.add_theme_constant_override("separation", 10)
	scroll_izq.add_child(vbox_izq)

	_agregar_subtitulo(vbox_izq, "📊 FINAL SYSTEM LEVELS (%)", Color(0.45, 0.85, 1.0))
	var orden_recursos := ['energia', 'aire', 'agua', 'alimentos', 'proteccion', 'animo']
	for id_sis in orden_recursos:
		if not rec_finales.has(id_sis):
			continue
		var val: float = float(rec_finales[id_sis])
		var nom_sis: String = GameData.sistemas.get(id_sis, {}).get('nombre', 'Crew Morale' if id_sis == 'animo' else id_sis.capitalize())
		var es_mej := GameState.esta_mejorado(id_sis)
		var icono: String = ICONOS_SISTEMAS.get(id_sis, '⚙️')

		var estado_texto := "Safe"
		var color_barra := Color(0.35, 0.95, 0.45)
		if val <= 0.0:
			estado_texto = "DEPLETED (0%)"
			color_barra = Color(1.0, 0.25, 0.25)
		elif val <= 25.0:
			estado_texto = "Critical"
			color_barra = Color(1.0, 0.35, 0.3)
		elif val <= 55.0:
			estado_texto = "Attention"
			color_barra = Color(1.0, 0.85, 0.3)

		var fila_contenedor := HBoxContainer.new()
		fila_contenedor.add_theme_constant_override("separation", 8)
		vbox_izq.add_child(fila_contenedor)

		if ICONOS_TEXTURAS.has(id_sis):
			var tex_ic := TextureRect.new()
			tex_ic.custom_minimum_size = Vector2(24, 24)
			tex_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_ic.texture = ICONOS_TEXTURAS[id_sis]
			fila_contenedor.add_child(tex_ic)

		var fila := VBoxContainer.new()
		fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_theme_constant_override("separation", 3)
		fila_contenedor.add_child(fila)

		var lbl_r := Label.new()
		lbl_r.text = "%s%s: %d%% — %s" % [
			nom_sis,
			" [Upgraded]" if es_mej else "",
			int(round(val)),
			estado_texto
		]
		lbl_r.add_theme_font_size_override("font_size", 13)
		lbl_r.add_theme_color_override("font_color", color_barra)
		fila.add_child(lbl_r)

		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(0, 16)
		barra.value = val
		barra.show_percentage = false

		var bg_sb_r := StyleBoxTexture.new()
		bg_sb_r.texture = TEX_BOTON_BARRA
		bg_sb_r.texture_margin_left = 6.0
		bg_sb_r.texture_margin_right = 6.0
		bg_sb_r.texture_margin_top = 2.0
		bg_sb_r.texture_margin_bottom = 2.0
		barra.add_theme_stylebox_override("background", bg_sb_r)

		var fill_sb_r := StyleBoxFlat.new()
		fill_sb_r.bg_color = color_barra
		fill_sb_r.set_corner_radius_all(3)
		barra.add_theme_stylebox_override("fill", fill_sb_r)

		fila.add_child(barra)

	_agregar_subtitulo(vbox_izq, "🛠️ UPGRADES & CONSUMPTION SAVINGS (%)", Color(1.0, 0.88, 0.35))
	var mejoras_elegidas: Array = r.get('mejoras', [])
	if mejoras_elegidas.is_empty():
		var lbl_sin := Label.new()
		lbl_sin.text = "No upgraded technologies."
		vbox_izq.add_child(lbl_sin)
	else:
		for id_m in mejoras_elegidas:
			var info_m: Dictionary = GameData.sistemas.get(id_m, {})
			var consumo_norm: float = absf(float(info_m.get('consumo_turno', {}).get('normal', 8.0)))
			var consumo_mej: float = absf(float(info_m.get('consumo_turno', {}).get('mejorado', 3.0)))
			var ahorro_pct: int = int(round(consumo_norm - consumo_mej))
			var tec_m: Dictionary = info_m.get('tecnologia', {}).get('mejorado', {})
			var lbl_m := Label.new()
			lbl_m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_m.text = "✓ %s (%s): Saved ~%d%% loss per Sol." % [
				info_m.get('nombre', id_m.capitalize()),
				tec_m.get('nombre', 'Advanced'),
				ahorro_pct
			]
			lbl_m.add_theme_font_size_override("font_size", 12)
			lbl_m.add_theme_color_override("font_color", Color(0.85, 0.98, 0.90))
			vbox_izq.add_child(lbl_m)

	# --- BITÁCORA NUTRICIONAL Y DE ÁNIMO (COMIDAS) ---
	_agregar_subtitulo(vbox_izq, "🍽️ NUTRITIONAL LOG & CREW MORALE", Color(1.0, 0.75, 0.4))
	var comidas_reg: Array = r.get('comidas', [])
	if comidas_reg.is_empty():
		var lbl_sin_c := Label.new()
		lbl_sin_c.text = "Standard rations consumed without additional log."
		lbl_sin_c.add_theme_font_size_override("font_size", 12)
		lbl_sin_c.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		vbox_izq.add_child(lbl_sin_c)
	else:
		var repeticiones := 0
		var platos_vistos := []
		for c_idx in comidas_reg.size():
			var item = comidas_reg[c_idx]
			var nom: String = item.get('nombre', 'Ration') if typeof(item) == TYPE_DICTIONARY else str(item)
			var tipo: String = item.get('tipo', 'Prepackaged') if typeof(item) == TYPE_DICTIONARY else 'Prepackaged'
			var id_p: String = item.get('id', nom) if typeof(item) == TYPE_DICTIONARY else str(item)
			
			if id_p in platos_vistos:
				repeticiones += 1
			platos_vistos.append(id_p)

			var fila_c := HBoxContainer.new()
			fila_c.add_theme_constant_override("separation", 8)
			vbox_izq.add_child(fila_c)

			var tex_c := TextureRect.new()
			tex_c.custom_minimum_size = Vector2(26, 26)
			tex_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var dict_comida: Dictionary = item if typeof(item) == TYPE_DICTIONARY else {'id': id_p, 'nombre': nom}
			tex_c.texture = _obtener_textura_comida(dict_comida)
			fila_c.add_child(tex_c)

			var lbl_item := Label.new()
			lbl_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_item.text = "• Sol %d: %s [%s]" % [c_idx + 1, nom, tipo]
			lbl_item.add_theme_font_size_override("font_size", 12)
			lbl_item.add_theme_color_override("font_color", Color(0.85, 0.95, 0.88))
			fila_c.add_child(lbl_item)

		var lbl_eval := Label.new()
		lbl_eval.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_eval.add_theme_font_size_override("font_size", 11)
		if repeticiones > 0:
			lbl_eval.text = "⚠️ Psychological Diagnosis: Crew suffered menu fatigue due to repetitive rations."
			lbl_eval.add_theme_color_override("font_color", Color(1.0, 0.65, 0.45))
		else:
			lbl_eval.text = "✨ Psychological Diagnosis: Varied diet with high nutrient density bolstered crew morale."
			lbl_eval.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65))
		vbox_izq.add_child(lbl_eval)

	# Columna Derecha: Bitácora de Variación de Porcentajes por Evento
	var panel_der := _crear_panel(Color(0.08, 0.11, 0.18, 0.95), Color(1.0, 0.78, 0.3))
	panel_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_der.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_cuerpo.add_child(panel_der)

	var scroll_der := ScrollContainer.new()
	scroll_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_der.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_der.add_child(scroll_der)

	var vbox_der := VBoxContainer.new()
	vbox_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_der.add_theme_constant_override("separation", 12)
	scroll_der.add_child(vbox_der)

	_agregar_subtitulo(vbox_der, "📜 EVENT IMPACT ON SYSTEMS (%)", Color(1.0, 0.88, 0.35))
	var historial: Array = r.get('historial', [])
	var mapa_eventos := {}
	for ev_d in GameData.eventos:
		mapa_eventos[ev_d['id']] = ev_d

	if historial.is_empty():
		var lbl_vacio := Label.new()
		lbl_vacio.text = "No system percentage changes recorded in this session."
		vbox_der.add_child(lbl_vacio)
	else:
		for item in historial:
			var ev_id: String = item.get('evento', '')
			var ev_orig: Dictionary = mapa_eventos.get(ev_id, {})
			var cambios: Dictionary = item.get('cambios', {})
			var textos_cambios := []
			for id_c in cambios:
				var d: float = float(cambios[id_c])
				if absf(d) >= 0.05:
					var nom_c: String = GameData.sistemas.get(id_c, {}).get('nombre', id_c.capitalize())
					var ic: String = ICONOS_SISTEMAS.get(id_c, '•')
					textos_cambios.append("%s %s: %+d%%" % [ic, nom_c, int(round(d))])

			var resumen_cambios := "No % changes"
			if not textos_cambios.is_empty():
				resumen_cambios = "Net impact: " + " | ".join(textos_cambios)

			var sis_ev: String = ev_orig.get('sistema', 'energia')
			var estaba_mej := GameState.esta_mejorado(sis_ev)
			var qhp: Dictionary = ev_orig.get('que_habria_pasado', {})
			var texto_qhp: String = qhp.get('normal' if estaba_mej else 'mejorado', '')
			if texto_qhp == '':
				texto_qhp = qhp.get('si_estuviera_normal' if estaba_mej else 'si_estuviera_mejorado', '')

			var caja_ev := _crear_panel(Color(0.12, 0.16, 0.25, 0.95), Color(0.35, 0.55, 0.8))
			vbox_der.add_child(caja_ev)
			var vb_ev := VBoxContainer.new()
			vb_ev.add_theme_constant_override("separation", 3)
			caja_ev.add_child(vb_ev)

			var lbl_ev_tit := Label.new()
			lbl_ev_tit.text = "Sol %d: %s  —  %s" % [
				int(item.get('turno', 1)),
				item.get('nombre', ev_id),
				resumen_cambios
			]
			lbl_ev_tit.add_theme_font_size_override("font_size", 13)
			lbl_ev_tit.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
			vb_ev.add_child(lbl_ev_tit)

			var p: float = float(item.get('puntaje', 0.0))
			if p > 0.0:
				var lbl_mitigado := Label.new()
				lbl_mitigado.text = "🛡️ Station repair prevented losing an additional %d%% of resources." % int(round(p * 50.0))
				lbl_mitigado.add_theme_font_size_override("font_size", 12)
				lbl_mitigado.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
				vb_ev.add_child(lbl_mitigado)

			var dato_ev: String = ev_orig.get('dato', '')
			if dato_ev != '':
				var lbl_dato := Label.new()
				lbl_dato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lbl_dato.text = "💡 NASA Fact: " + dato_ev
				lbl_dato.add_theme_font_size_override("font_size", 12)
				lbl_dato.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
				vb_ev.add_child(lbl_dato)

			if texto_qhp != '':
				var lbl_qhp := Label.new()
				lbl_qhp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lbl_qhp.text = "🔄 What would have happened?: " + texto_qhp
				lbl_qhp.add_theme_font_size_override("font_size", 12)
				lbl_qhp.add_theme_color_override("font_color", Color(0.86, 0.84, 0.98))
				vb_ev.add_child(lbl_qhp)

	# --- EVENTOS DEL MAZO QUE NO OCURRIERON (¿QUÉ HABRÍA PASADO?) ---
	var no_salieron: Array = r.get('eventos_no_salieron', [])
	if not no_salieron.is_empty():
		_agregar_subtitulo(vbox_der, "🔮 UNOCCURRED EVENTS: WHAT WOULD HAVE HAPPENED? (MARQUITOS)", Color(0.85, 0.65, 1.0))
		for ev_ns in no_salieron:
			var sis_ns: String = ev_ns.get('sistema', 'energia')
			var nom_sis_ns: String = GameData.sistemas.get(sis_ns, {}).get('nombre', sis_ns.capitalize())
			var mej_ns: bool = GameState.esta_mejorado(sis_ns)
			var qhp_ns: Dictionary = ev_ns.get('que_habria_pasado', {})
			var impacto_qhp: String = qhp_ns.get('mejorado' if mej_ns else 'normal', '')
			if impacto_qhp == '':
				impacto_qhp = qhp_ns.get('si_estuviera_mejorado' if mej_ns else 'si_estuviera_normal', '')

			var caja_ns := _crear_panel(Color(0.10, 0.12, 0.22, 0.95), Color(0.65, 0.45, 0.95))
			vbox_der.add_child(caja_ns)
			var vb_ns := VBoxContainer.new()
			vb_ns.add_theme_constant_override("separation", 3)
			caja_ns.add_child(vb_ns)

			var lbl_ns_tit := Label.new()
			lbl_ns_tit.text = "⚠️ %s (System: %s — %s)" % [
				ev_ns.get('nombre', 'Event'),
				nom_sis_ns,
				"Upgraded Technology" if mej_ns else "Standard Technology"
			]
			lbl_ns_tit.add_theme_font_size_override("font_size", 13)
			lbl_ns_tit.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
			vb_ns.add_child(lbl_ns_tit)

			var lbl_ns_desc := Label.new()
			lbl_ns_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_ns_desc.text = "🤖 Marquitos: 'If it had hit your habitat: %s'" % impacto_qhp
			lbl_ns_desc.add_theme_font_size_override("font_size", 12)
			lbl_ns_desc.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
			vb_ns.add_child(lbl_ns_desc)

	# --- SECCIÓN DE DATOS CURIOSOS ---
	_agregar_subtitulo(vbox_der, "🌌 DID YOU KNOW? MARS FACTS (NASA)", Color(0.45, 0.98, 0.65))
	var curiosidades := DATOS_CURIOSOS_MARTE.duplicate()
	curiosidades.shuffle()
	for i in range(mini(3, curiosidades.size())):
		var lbl_cur := Label.new()
		lbl_cur.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_cur.text = curiosidades[i]
		lbl_cur.add_theme_font_size_override("font_size", 12)
		lbl_cur.add_theme_color_override("font_color", Color(0.92, 0.97, 0.94))
		vbox_der.add_child(lbl_cur)

	# --- BOTONES INFERIORES ---
	var hbox_botones := HBoxContainer.new()
	hbox_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_botones.add_theme_constant_override("separation", 20)
	vbox_raiz.add_child(hbox_botones)

	var btn_seleccion := Button.new()
	btn_seleccion.text = "🔄 Play Again (Change Upgrades)"
	btn_seleccion.custom_minimum_size = Vector2(280, 42)
	_estilar_boton(btn_seleccion, Color(0.25, 0.45, 0.70, 0.95))
	btn_seleccion.pressed.connect(_on_reiniciar)
	hbox_botones.add_child(btn_seleccion)

	var btn_reintentar := Button.new()
	btn_reintentar.text = "🚀 Replay with Same Upgrades"
	btn_reintentar.custom_minimum_size = Vector2(300, 42)
	_estilar_boton(btn_reintentar, Color(0.20, 0.60, 0.40, 0.95))
	btn_reintentar.pressed.connect(_on_reintentar_misma_config)
	hbox_botones.add_child(btn_reintentar)

	var btn_menu := Button.new()
	btn_menu.text = "🏠 Main Menu"
	btn_menu.custom_minimum_size = Vector2(180, 42)
	_estilar_boton(btn_menu, Color(0.35, 0.38, 0.48, 0.95))
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file('res://scenes/selection/selection_screen.tscn'))
	hbox_botones.add_child(btn_menu)

func _estilar_boton(btn: Button, color_tinte: Color) -> void:
	var sb := StyleBoxTexture.new()
	sb.texture = TEX_BOTON_BARRA
	sb.texture_margin_left = 6.0
	sb.texture_margin_right = 6.0
	sb.texture_margin_top = 2.0
	sb.texture_margin_bottom = 2.0
	sb.modulate_color = color_tinte
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := sb.duplicate()
	sb_h.modulate_color = color_tinte.lightened(0.25)
	btn.add_theme_stylebox_override("hover", sb_h)

	var sb_p := sb.duplicate()
	sb_p.modulate_color = color_tinte.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", sb_p)

func _crear_panel(color_fondo: Color, color_borde: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color_fondo
	s.border_color = color_borde
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", s)
	return p

func _agregar_subtitulo(padre: Control, texto: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", color)
	padre.add_child(lbl)

func _on_reiniciar() -> void:
	get_tree().change_scene_to_file('res://scenes/selection/selection_screen.tscn')

func _on_reintentar_misma_config() -> void:
	var mejoras_actuales := GameState.mejoras.duplicate()
	if mejoras_actuales.is_empty():
		mejoras_actuales = ['energia', 'agua']
	GameState.iniciar_partida(mejoras_actuales)
	get_tree().change_scene_to_file('res://Animacion/node_22d.tscn')

func _obtener_textura_comida(opc: Dictionary) -> Texture2D:
	var ruta_img: String = opc.get('imagen', '')
	if ruta_img != "" and ResourceLoader.exists(ruta_img):
		return load(ruta_img)
	
	var id_c: String = opc.get('id', '').to_lower()
	var nom_c: String = opc.get('nombre', '').to_lower()
	
	if 'ensalada' in id_c or 'ensalada' in nom_c or 'veggie' in nom_c or 'cultivo' in nom_c or 'salad' in id_c or 'salad' in nom_c:
		if ResourceLoader.exists("res://comida/salad.png"):
			return load("res://comida/salad.png")
	elif 'ravioli' in id_c or 'ravioli' in nom_c:
		if ResourceLoader.exists("res://comida/ravioli.png"):
			return load("res://comida/ravioli.png")
	elif 'pavo' in id_c or 'pavo' in nom_c or 'turkey' in id_c or 'turkey' in nom_c:
		if ResourceLoader.exists("res://comida/pavo.png"):
			return load("res://comida/pavo.png")
	elif 'sopa' in id_c or 'sopa' in nom_c or 'soup' in id_c or 'caldo' in nom_c or 'soup' in nom_c:
		if ResourceLoader.exists("res://comida/soup.png"):
			return load("res://comida/soup.png")
	elif 'avena' in id_c or 'avena' in nom_c or 'oats' in id_c or 'oatmeal' in nom_c:
		if ResourceLoader.exists("res://comida/avena.png"):
			return load("res://comida/avena.png")
	elif 'pollo' in id_c or 'pollo' in nom_c or 'chicken' in id_c or 'chicken' in nom_c:
		if ResourceLoader.exists("res://comida/arroz con pollo.png"):
			return load("res://comida/arroz con pollo.png")
	elif 'fruto' in id_c or 'fruto' in nom_c or 'seco' in id_c or 'nuez' in nom_c or 'nut' in id_c or 'nuts' in nom_c:
		if ResourceLoader.exists("res://comida/fruto seco.png"):
			return load("res://comida/fruto seco.png")
	elif 'pasta' in id_c or 'pasta' in nom_c or 'fideo' in nom_c:
		if ResourceLoader.exists("res://comida/pasta.png"):
			return load("res://comida/pasta.png")
	elif 'huevo' in id_c or 'egg' in id_c or 'huevo' in nom_c or 'omelette' in nom_c:
		if ResourceLoader.exists("res://comida/eggs.png"):
			return load("res://comida/eggs.png")
	elif 'frijol' in id_c or 'frijol' in nom_c or 'tortilla' in nom_c or 'burrito' in nom_c or 'bean' in id_c or 'beans' in nom_c:
		if ResourceLoader.exists("res://comida/arroz con frijoles.png"):
			return load("res://comida/arroz con frijoles.png")
	elif 'arroz' in id_c or 'arroz' in nom_c or 'curry' in nom_c or 'salmon' in nom_c or 'rice' in id_c or 'rice' in nom_c or 'fish' in nom_c:
		if ResourceLoader.exists("res://comida/rice.png"):
			return load("res://comida/rice.png")
	
	if ResourceLoader.exists("res://comida/rice.png"):
		return load("res://comida/rice.png")
	return null



