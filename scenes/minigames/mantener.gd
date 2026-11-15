extends "res://scenes/minigames/minijuego_simple.gd"
## MANTENER (Polvo marciano): mantén Espacio (o el botón) presionado hasta llenar %Progreso.
## Gráficos editables: %Progreso (barra) y %Boton.

@export var velocidad_llenado: float = 0.55   # fracción por segundo
@export var velocidad_vaciado: float = 0.25

@onready var progreso: Range = %Progreso

var _valor := 0.0
var _boton_abajo := false

func _ready() -> void:
	var b := get_node_or_null('%Boton')
	if b is BaseButton:
		b.focus_mode = Control.FOCUS_NONE
		b.button_down.connect(func(): _boton_abajo = true)
		b.button_up.connect(func(): _boton_abajo = false)

func _empezar() -> void:
	_valor = 0.0
	progreso.value = 0.0

func _actualizar(delta: float) -> void:
	var apretando := _boton_abajo or Input.is_key_pressed(KEY_SPACE)
	var cambio := velocidad_llenado if apretando else -velocidad_vaciado
	_valor = clampf(_valor + cambio * delta, 0.0, 1.0)
	progreso.value = _valor * 100.0
	if _valor >= 1.0:
		terminar(1.0)

func _puntaje_por_tiempo() -> float:
	return _valor * 0.7
