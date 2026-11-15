class_name EventDeck
extends RefCounted
## Genera el mazo de 5 eventos cumpliendo las reglas de diseño. No usa nodos.

const TAMANO := 5
const MAX_INTENTOS := 300

static func generar(eventos: Array, mejoras: Array) -> Array:
	var candidato: Array = []
	for _i in MAX_INTENTOS:
		candidato = eventos.duplicate()
		candidato.shuffle()
		candidato = candidato.slice(0, TAMANO)
		if es_valido(candidato, mejoras):
			return candidato
	push_warning('EventDeck: sin mazo válido en %d intentos; se usa el último' % MAX_INTENTOS)
	return candidato

static func es_valido(mazo: Array, mejoras: Array) -> bool:
	if mazo.is_empty() or not mazo[0].get('suave', false):
		return false                              # el turno 1 es un evento suave
	var positivos := 0
	var golpes_sin_mejora := 0
	for i in mazo.size():
		var ev: Dictionary = mazo[i]
		if ev.get('positivo', false):
			positivos += 1
		elif not (ev['sistema'] in mejoras):
			golpes_sin_mejora += 1
		if i > 0 and ev['sistema'] == mazo[i - 1]['sistema']:
			return false                          # nunca dos seguidos del mismo sistema
	return positivos <= 1 and golpes_sin_mejora >= 2
