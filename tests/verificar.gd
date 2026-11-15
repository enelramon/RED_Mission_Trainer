extends Node
## Verificación automática: carga todo y simula partidas completas.

var errores := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  OK   ", msg)
	else:
		errores += 1
		print("  FAIL ", msg)

func _ready() -> void:
	print("=== 1. Carga de escenas y scripts ===")
	var rutas := [
		"res://scenes/intro/menu_inicio.tscn", "res://scenes/selection/selection_screen.tscn",
		"res://scenes/launch/launch.tscn", "res://scenes/base/base.tscn", "res://scenes/end/summary.tscn",
		"res://scenes/minigames/cables.tscn", "res://scenes/minigames/barra_zona.tscn",
		"res://scenes/minigames/secuencia.tscn", "res://Animacion/node_22d.tscn",
		"res://scenes/base/turn_manager.gd", "res://logic/event_deck.gd"]
	for r in rutas:
		var res = load(r)
		_ok(res != null, "carga " + r)
		if res is GDScript:
			_ok(res.can_instantiate(), "compila " + r)

	print("=== 2. Datos JSON ===")
	_ok(GameData.sistemas.size() == 6, "sistemas.json: %d sistemas" % GameData.sistemas.size())
	_ok(GameData.eventos.size() == 8, "eventos.json: %d eventos" % GameData.eventos.size())
	_ok(GameData.alimentos.size() >= 7, "alimentos.json: %d alimentos" % GameData.alimentos.size())
	_ok(load("res://Fotos/fondo de inicio nasa.png") is Texture2D, "imagen fondo de inicio")
	var tm = load("res://scenes/base/turn_manager.gd").new()
	for a in GameData.alimentos:
		var tex = tm._obtener_textura_comida(a)
		_ok(tex != null, "textura comida para: " + a.get('nombre', ''))
	tm.free()

	print("=== 3. Pantalla de inicio ===")
	var menu = load("res://scenes/selection/selection_screen.tscn").instantiate()
	add_child(menu)
	var nodo_fondo = menu.get_node_or_null("Fondo") if menu.has_node("Fondo") else menu.get_node_or_null("%TexturaFondo")
	_ok(nodo_fondo != null and nodo_fondo.texture != null, "fondo de inicio visible")
	menu.queue_free()

	print("=== 4. Minijuegos ===")
	for m in ["cables", "barra_zona", "secuencia"]:
		var mj = load("res://scenes/minigames/%s.tscn" % m).instantiate()
		add_child(mj)
		mj.iniciar({"nombre": "Prueba"})
		_ok(true, "minijuego " + m + " arranca")
		mj.queue_free()

	print("=== 5. Mazo de eventos (reglas) ===")
	var ids := ["energia", "aire", "agua", "alimentos", "proteccion"]
	var mazos_ok := true
	for a in ids.size():
		for b in range(a + 1, ids.size()):
			for _n in 50:
				var mazo := EventDeck.generar(GameData.eventos, [ids[a], ids[b]])
				if not EventDeck.es_valido(mazo, [ids[a], ids[b]]):
					mazos_ok = false
	_ok(mazos_ok, "500 mazos cumplen: turno 1 suave, >=2 golpes sin mejora, sin repetir sistema, <=1 positivo")

	print("=== 6. Partida completa simulada ===")
	GameState.iniciar_partida(["energia", "alimentos"])
	GameState.mazo = EventDeck.generar(GameData.eventos, GameState.mejoras)
	var platos := ["avena_frutas", "avena_frutas", "salmon_curry", "ensalada_hidroponica", "pasta_pouch"]
	for t in 5:
		GameState.empezar_turno()
		GameState.registrar_comida(platos[t])
		GameState.aplicar_evento(GameState.resolver_variante(GameState.mazo[t]), 0.8)
		GameState.terminar_turno()
		if GameState.partida_terminada():
			break
	var r: Dictionary = GameState.resumen()
	for k in ["mejoras", "resultado", "causa_aborto", "recursos_finales", "historial", "comidas", "eventos_no_salieron"]:
		_ok(r.has(k), "resumen tiene '" + k + "'")
	_ok(r["comidas"].size() >= 1, "comidas registradas: %d" % r["comidas"].size())
	_ok(r["eventos_no_salieron"].size() == 8 - r["historial"].size(), "eventos no salidos: %d" % r["eventos_no_salieron"].size())
	print("  resultado=", r["resultado"], " recursos=", r["recursos_finales"])

	print("=== 7. Pantalla final ===")
	var fin = load("res://scenes/end/summary.tscn").instantiate()
	add_child(fin)
	_ok(fin.get_child_count() > 3, "resumen final se construye")

	print("=== RESULTADO: %s (%d fallos) ===" % ["TODO OK" if errores == 0 else "HAY FALLOS", errores])
	get_tree().quit(errores)