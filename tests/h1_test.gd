extends Node

func _ready() -> void:
	GameState.iniciar_partida(['energia', 'agua'])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: GameState.cambiar('energia', -15.0, 'prueba')
			KEY_2: GameState.cambiar('aire', -15.0, 'prueba')
			KEY_3: GameState.cambiar('agua', -15.0, 'prueba')
			KEY_4: GameState.cambiar('alimentos', -15.0, 'prueba')
			KEY_5: GameState.cambiar('proteccion', -15.0, 'prueba')
			KEY_6: GameState.cambiar('energia', 15.0, 'prueba')
