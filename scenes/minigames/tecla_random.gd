extends "res://scenes/minigames/minijuego_simple.gd"
## TECLA AL AZAR (Tornado): presiona la tecla que aparece en %Tecla antes de que se acabe el tiempo.
## Gráficos editables: %Tecla (Label) y %TeclaFondo (el cuadro detrás de la letra).

@export var teclas: PackedStringArray = PackedStringArray(['Q', 'E', 'R', 'F', 'Z', 'X', 'C', 'V'])

@onready var tecla_label: Label = %Tecla

var _objetivo := ''

func _empezar() -> void:
	_objetivo = teclas[randi() % teclas.size()]
	tecla_label.text = _objetivo

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if OS.get_keycode_string(event.keycode) == _objetivo:
			get_viewport().set_input_as_handled()
			terminar(1.0)
