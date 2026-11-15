extends "res://scenes/minigames/minijuego_simple.gd"
## BARRA CON ZONA: detén el indicador dentro de la zona verde (Espacio / E / botón).
## Gráficos editables: %Pista (fondo de la barra), %Zona (zona buena), %Indicador (lo que se mueve).

@export var velocidad: float = 320.0       # píxeles por segundo
@export var ancho_zona_min: float = 0.18   # fracción del ancho de la pista
@export var ancho_zona_max: float = 0.28

@onready var pista: Control = %Pista
@onready var zona: Control = %Zona
@onready var indicador: Control = %Indicador

var _dir := 1.0

func _ready() -> void:
	super._ready()
	var b := get_node_or_null('%Boton')
	if b is BaseButton:
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_fijar)

func _empezar() -> void:
	var ancho_pista := pista.size.x
	zona.size.x = ancho_pista * randf_range(ancho_zona_min, ancho_zona_max)
	zona.position.x = randf_range(0.0, ancho_pista - zona.size.x)
	indicador.position.x = 0.0
	_dir = 1.0

func _actualizar(delta: float) -> void:
	var maximo := pista.size.x - indicador.size.x
	indicador.position.x += _dir * velocidad * delta
	if indicador.position.x >= maximo:
		indicador.position.x = maximo
		_dir = -1.0
	elif indicador.position.x <= 0.0:
		indicador.position.x = 0.0
		_dir = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if es_accion(event):
		get_viewport().set_input_as_handled()
		_fijar()

func _fijar() -> void:
	if _cerrado:
		return
	var centro := indicador.position.x + indicador.size.x * 0.5
	var ini := zona.position.x
	var fin := ini + zona.size.x
	if centro >= ini and centro <= fin:
		if SoundManager != null:
			SoundManager.play_laser()
			SoundManager.play_success()
		terminar(1.0)
	else:
		if SoundManager != null:
			SoundManager.play_error()
		var dist := minf(absf(centro - ini), absf(centro - fin))
		terminar(clampf(0.6 - dist / pista.size.x * 2.0, 0.1, 0.6))
