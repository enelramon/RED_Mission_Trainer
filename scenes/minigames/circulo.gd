extends "res://scenes/minigames/minijuego_simple.gd"
## CÍRCULO (Erupción solar): detén la aguja cuando pase por la marca (Espacio / E / botón).
## Gráficos editables: %Anillo (el círculo), %PivoteZona/Zona (la marca), %PivoteAguja/Aguja.
## Los "Pivote" son Control vacíos en el centro del anillo: lo que cuelgue de ellos gira.

@export var velocidad_giro: float = 3.0      # radianes por segundo
@export var tolerancia_grados: float = 20.0

@onready var piv_aguja: Control = %PivoteAguja
@onready var piv_zona: Control = %PivoteZona

func _ready() -> void:
	var b := get_node_or_null('%Boton')
	if b is BaseButton:
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_fijar)

func _empezar() -> void:
	piv_zona.rotation = randf() * TAU
	piv_aguja.rotation = wrapf(piv_zona.rotation + PI, 0.0, TAU)

func _actualizar(delta: float) -> void:
	piv_aguja.rotation = wrapf(piv_aguja.rotation + velocidad_giro * delta, 0.0, TAU)

func _unhandled_input(event: InputEvent) -> void:
	if es_accion(event):
		get_viewport().set_input_as_handled()
		_fijar()

func _fijar() -> void:
	if _cerrado:
		return
	var diff := absf(rad_to_deg(angle_difference(piv_aguja.rotation, piv_zona.rotation)))
	if diff <= tolerancia_grados:
		terminar(1.0)
	elif diff <= tolerancia_grados * 2.5:
		terminar(0.5)
	else:
		terminar(0.15)
