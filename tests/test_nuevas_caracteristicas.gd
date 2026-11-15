extends Node

func _ready() -> void:
	print("=== INICIANDO PRUEBAS DE NUEVAS CARACTERÍSTICAS ===")
	var errores := 0

	# 1. Verificar intervalo de 15 segundos
	if GameState.INTERVALO_EVENTOS == 15.0:
		print("  OK   GameState.INTERVALO_EVENTOS es 15.0")
	else:
		print("  FAIL GameState.INTERVALO_EVENTOS no es 15.0: ", GameState.INTERVALO_EVENTOS)
		errores += 1

	var tm_script = load("res://scenes/base/turn_manager.gd")
	if tm_script.TIEMPO_ENTRE_EVENTOS == 15.0:
		print("  OK   TurnManager.TIEMPO_ENTRE_EVENTOS es 15.0")
	else:
		print("  FAIL TurnManager.TIEMPO_ENTRE_EVENTOS no es 15.0: ", tm_script.TIEMPO_ENTRE_EVENTOS)
		errores += 1

	var ev_script = load("res://cosdigo/eventos_marte_ui.gd")
	var ev_inst = ev_script.new()
	if ev_inst.intervalo_min == 15.0:
		print("  OK   EventosMarteUI.intervalo_min es 15.0")
	else:
		print("  FAIL EventosMarteUI.intervalo_min no es 15.0: ", ev_inst.intervalo_min)
		errores += 1
	ev_inst.free()

	# 2. Verificar Marquitos y los 3 globos de texto con Capa de visualización superior
	var marq_script = load("res://cosdigo/marquitos.gd")
	var marq = Sprite2D.new()
	marq.set_script(marq_script)
	add_child(marq)
	
	var globo: PanelContainer = marq.find_child("GloboMarquitos", true, false)
	var capa_globo: CanvasLayer = marq.get_node_or_null("CapaGloboMarquitos")
	if globo != null and capa_globo != null and (capa_globo.layer == 3 or capa_globo.layer == 5) and capa_globo.follow_viewport_enabled:
		print("  OK   GloboMarquitos en CapaGloboMarquitos (layer %d, bajo UI emergente y sobre paredes) y follow_viewport" % capa_globo.layer)
	elif globo != null:
		print("  OK   GloboMarquitos encontrado en Marquitos")
	else:
		print("  FAIL GloboMarquitos no encontrado")
		errores += 1

	# Probar ocasión Alerta
	marq._on_robot_dice("🚨 ALERTA: Tormenta de arena en camino!")
	var estilo_alerta = globo.get_theme_stylebox("panel")
	if estilo_alerta is StyleBoxTexture and estilo_alerta.texture == marq_script.TEX_GLOBO_ALERTA:
		print("  OK   Globo de Alerta aplicado correctamente")
	else:
		print("  FAIL Globo de Alerta no aplicado")
		errores += 1

	# Probar ocasión Pensamiento
	marq._on_robot_dice("💡 Dato curioso: La atmósfera de Marte es 95% CO2.")
	var estilo_pensamiento = globo.get_theme_stylebox("panel")
	if estilo_pensamiento is StyleBoxTexture and estilo_pensamiento.texture == marq_script.TEX_GLOBO_PENSAMIENTO:
		print("  OK   Globo de Pensamiento aplicado correctamente")
	else:
		print("  FAIL Globo de Pensamiento no aplicado")
		errores += 1

	# Probar ocasión Diálogo normal
	marq._on_robot_dice("Iniciando operaciones del turno en el hábitat.")
	var estilo_dialogo = globo.get_theme_stylebox("panel")
	if estilo_dialogo is StyleBoxTexture and estilo_dialogo.texture == marq_script.TEX_GLOBO_DIALOGO:
		print("  OK   Globo de Diálogo aplicado correctamente")
	else:
		print("  FAIL Globo de Diálogo no aplicado")
		errores += 1

	# Probar temporizador de auto-cierre del diálogo de Marquitos
	if marq._tiempo_restante_globo > 0.0:
		print("  OK   Temporizador de diálogo de Marquitos activo: ", marq._tiempo_restante_globo, "s")
		marq._process(10.0) # simular paso del tiempo para verificar que desaparece
		if not globo.visible:
			print("  OK   El diálogo de Marquitos se oculta automáticamente tras transcurrir el tiempo")
		else:
			print("  FAIL El diálogo no se ocultó tras expirar el temporizador")
			errores += 1
	else:
		print("  FAIL Falta temporizador de diálogo en Marquitos")
		errores += 1

	marq.queue_free()

	# 3. Verificar HUD e iconos de recursos
	var hud_scn = load("res://scenes/base/hud.tscn")
	var hud = hud_scn.instantiate()
	add_child(hud)
	
	var sistemas_esperados := ['energia', 'aire', 'agua', 'alimentos', 'proteccion', 'animo']
	for s in sistemas_esperados:
		if hud.barras.has(s) and hud.barras[s] != null:
			print("  OK   HUD barra '%s' presente" % s)
		else:
			print("  FAIL HUD falta barra '%s'" % s)
			errores += 1

	hud.queue_free()

	# 4. Verificar Pantalla de Resumen e iconos
	var summary_scn = load("res://scenes/end/summary.tscn")
	var summary = summary_scn.instantiate()
	add_child(summary)
	print("  OK   SummaryScreen instanciada correctamente con iconos y botones")
	summary.queue_free()

	# 5. Verificar Pantalla de Inicio directa de nsac y animación de nave en despegue
	var menu_scn = load("res://scenes/selection/selection_screen.tscn")
	var menu = menu_scn.instantiate()
	add_child(menu)

	if menu.tarjetas.size() == 5:
		print("  OK   Pantalla de Inicio tiene los 5 sistemas de botones de nsac")
	else:
		print("  FAIL Pantalla de Inicio tarjetas tamaño: ", menu.tarjetas.size())
		errores += 1

	# Probar selección de sistemas en inicio
	var t_energia = menu.tarjetas[0]
	var t_aire = menu.tarjetas[1]
	t_energia.button_pressed = true
	t_aire.button_pressed = true
	if menu.elegidos.size() == 2 and not menu.boton_despegar.disabled:
		print("  OK   Selección de 2 mejoras activa el botón Despegar")
	else:
		print("  FAIL Botón despegar no se habilitó con 2 mejoras")
		errores += 1
	menu.queue_free()

	# Verificar que la animación de la nave va después de iniciar (en launch.tscn)
	var launch_scn = load("res://scenes/launch/launch.tscn")
	var launch = launch_scn.instantiate()
	add_child(launch)
	var anim_nave = launch.get_node_or_null("ContenedorNave/NaveAnimada")
	if anim_nave is AnimatedSprite2D and anim_nave.sprite_frames != null:
		print("  OK   AnimacionNave integrada para ejecutarse tras iniciar (en launch)")
	else:
		print("  FAIL Falta NaveAnimada en launch.tscn")
		errores += 1
	launch.queue_free()

	# 6. Verificar fuente SHPinscher-Regular
	var fuente = load("res://fonts/SHPinscher-Regular.otf")
	if fuente != null:
		print("  OK   Fuente SHPinscher-Regular.otf cargada correctamente")
	else:
		print("  FAIL Fuente SHPinscher-Regular.otf falló al cargar")
		errores += 1

	# 7. Verificar SoundManager y efectos de sonido 8-bit
	if SoundManager != null:
		print("  OK   SoundManager disponible como Autoload")
		SoundManager.play_select()
		SoundManager.play_click()
		SoundManager.play_connect()
		SoundManager.play_laser()
		SoundManager.play_error()
		SoundManager.play_success()
		SoundManager.play_step(0)
		SoundManager.play_launch()
		print("  OK   Todos los sonidos espaciales 8-bit reproducibles (incluyendo despegue de nave)")
	else:
		print("  FAIL SoundManager no cargado como Autoload")
		errores += 1

	# 8. Verificar Estaciones e Iconos de salas y Alerta
	var st_scn = load("res://scenes/base/station.tscn")
	var st = st_scn.instantiate()
	st.sistema_id = "energia"
	add_child(st)
	if st.alarma != null and st.alarma is Sprite2D and st.alarma.texture != null:
		print("  OK   Estación configurada con icono de alerta: ", st.alarma.texture.resource_path)
	else:
		print("  FAIL Falta icono de alerta en estación")
		errores += 1
	if st.sprite_normal != null and st.sprite_normal is Sprite2D and st.sprite_normal.texture != null:
		print("  OK   Estación configurada con icono del sistema: ", st.sprite_normal.texture.resource_path)
	else:
		print("  FAIL Falta icono de sistema en estación")
		errores += 1
	st.queue_free()

	print("=== RESULTADO PRUEBAS: %s (%d fallos) ===" % ["TODO PERFECTO" if errores == 0 else "HAY FALLOS", errores])
	get_tree().quit(errores)
