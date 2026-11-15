extends Node
## SOLO PARA PRUEBAS. Borrar antes de exportar.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_8:
		GameState.cambiar('aire', -100.0, 'tecla de prueba')
