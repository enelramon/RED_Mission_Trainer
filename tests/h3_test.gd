extends Node

func _ready() -> void:
	var mejoras := ['energia', 'agua']
	var invalidos := 0
	for _i in 1000:
		var mazo := EventDeck.generar(GameData.eventos, mejoras)
		if not EventDeck.es_valido(mazo, mejoras):
			invalidos += 1
	print('Mazos inválidos: %d de 1000' % invalidos)
	for ev in EventDeck.generar(GameData.eventos, mejoras):
		print('- ', ev['nombre'])
