extends Node

const IDS := ['energia', 'aire', 'agua', 'alimentos', 'proteccion']
const PARTIDAS := 500

func _ready() -> void:
	for a in IDS.size():
		for b in range(a + 1, IDS.size()):
			_simular([IDS[a], IDS[b]])

func _simular(mejoras: Array) -> void:
	var abortadas := 0
	for _n in PARTIDAS:
		GameState.iniciar_partida(mejoras)
		GameState.mazo = EventDeck.generar(GameData.eventos, mejoras)
		for t in GameState.TOTAL_TURNOS:
			GameState.empezar_turno()
			var evento := GameState.resolver_variante(GameState.mazo[t])
			GameState.aplicar_evento(evento, randf())
			GameState.terminar_turno()
			if GameState.partida_terminada():
				break
		if GameState.resultado_final == GameState.Resultado.ABORTADA:
			abortadas += 1
	print('%s -> abortadas: %d de %d' % [str(mejoras), abortadas, PARTIDAS])
