extends "res://scenes/minigames/minijuego_simple.gd"
## SECUENCIA: presiona los botones en el orden que muestra %Orden (clic o teclas 1-4).

func _init() -> void:
	tiempo_limite = 12.0

@export var penalizacion_error: float = 0.25

@onready var orden_label: Label = %Orden
@onready var botones: Array = %Botones.get_children()

var _orden: Array = []
var _paso := 0
var _errores := 0

func _ready() -> void:
	super._ready()
	for i in botones.size():
		botones[i].focus_mode = Control.FOCUS_NONE
		botones[i].pressed.connect(_pulsar.bind(i))

func _empezar() -> void:
	_orden = range(botones.size())
	_orden.shuffle()
	_paso = 0
	_errores = 0
	for i in botones.size():
		botones[i].disabled = false
		botones[i].text = str(i + 1)
	_mostrar()

func _mostrar() -> void:
	var partes := PackedStringArray()
	for k in _orden.size():
		var n := str(_orden[k] + 1)
		if k < _paso:
			partes.append('[ ✓ %s ]' % n)
		elif k == _paso:
			partes.append('▶ [ %s ] ◀' % n)
		else:
			partes.append('[ %s ]' % n)
	orden_label.text = "Required Sequence:   " + " ➔ ".join(partes)
	if _errores > 0:
		orden_label.text += "    |    ⚠️ Errors: %d" % _errores

func _pulsar(i: int) -> void:
	if _cerrado:
		return
	if i == _orden[_paso]:
		botones[i].disabled = true
		botones[i].text = "✓ " + str(i + 1)
		_paso += 1
		if _paso >= _orden.size():
			if SoundManager != null:
				SoundManager.play_success()
			terminar(clampf(1.0 - penalizacion_error * _errores, 0.0, 1.0))
			return
		else:
			if SoundManager != null:
				SoundManager.play_step(_paso - 1)
	else:
		_errores += 1
		if SoundManager != null:
			SoundManager.play_error()
	_mostrar()

func _puntaje_por_tiempo() -> float:
	return 0.5 * float(_paso) / float(maxi(1, _orden.size()))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < botones.size():
			get_viewport().set_input_as_handled()
			_pulsar(idx)
