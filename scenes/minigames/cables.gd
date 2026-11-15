extends "res://scenes/minigames/minijuego_simple.gd"
## CABLES estilo Among Us: arrastra (o haz clic) desde un cable de la izquierda
## hasta el del mismo color a la derecha. Las líneas se dibujan encima del panel.

func _init() -> void:
	tiempo_limite = 14.0

@export var penalizacion_error: float = 0.2

@onready var izq: Array = %Izquierda.get_children()
@onready var der: Array = %Derecha.get_children()

const COLORES: Array[Color] = [
	Color(0.95, 0.25, 0.25), # Rojo
	Color(0.98, 0.85, 0.20), # Amarillo
	Color(0.22, 0.68, 1.00), # Azul
	Color(0.22, 0.88, 0.42), # Verde
]
const NOMBRES: Array[String] = ["Red", "Yellow", "Blue", "Green"]

var _capa: Control = null          # capa transparente para dibujar los cables
var _sel: int = -1                 # cable izquierdo agarrado
var _conexiones: Dictionary = {}   # índice izquierdo -> índice derecho
var _errores: int = 0

func _ready() -> void:
	super._ready()
	_capa = Control.new()
	_capa.name = "CapaCables"
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_capa)
	_capa.draw.connect(_dibujar)
	for i in izq.size():
		var b: Button = izq[i]
		b.focus_mode = Control.FOCUS_NONE
		b.text = NOMBRES[i % NOMBRES.size()] + "  ●"
		b.add_theme_color_override("font_color", COLORES[i % COLORES.size()])
		b.button_down.connect(_agarrar.bind(i))
	for j in der.size():
		var b: Button = der[j]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_soltar_en.bind(j))

func _empezar() -> void:
	var orden: Array = range(der.size())
	orden.shuffle()
	for k in der.size():
		var b: Button = der[k]
		var c: int = orden[k]
		b.set_meta("color_idx", c)
		b.text = "●  " + NOMBRES[c % NOMBRES.size()]
		b.add_theme_color_override("font_color", COLORES[c % COLORES.size()])
	_conexiones.clear()
	_sel = -1
	_errores = 0

func _actualizar(_delta: float) -> void:
	if _capa != null:
		_capa.queue_redraw()

func _input(event: InputEvent) -> void:
	# Al soltar el ratón mientras se arrastra: ¿sobre qué terminal derecho?
	if _cerrado or _sel < 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var pos: Vector2 = get_global_mouse_position()
		for j in der.size():
			var b: Button = der[j]
			if b.get_global_rect().has_point(pos):
				_soltar_en(j)
				return
		var origen: Button = izq[_sel]
		if not origen.get_global_rect().has_point(pos):
			_sel = -1   # soltó en el vacío: el cable vuelve

func _agarrar(i: int) -> void:
	if _cerrado or _conexiones.has(i):
		return
	_sel = i
	if SoundManager != null:
		SoundManager.play_click()

func _soltar_en(j: int) -> void:
	if _cerrado or _sel < 0:
		return
	var b: Button = der[j]
	var c: int = int(b.get_meta("color_idx", -1))
	if c == _sel and not _conexiones.values().has(j):
		_conexiones[_sel] = j
		var bi: Button = izq[_sel]
		bi.disabled = true
		b.disabled = true
		_sel = -1
		if _conexiones.size() >= izq.size():
			if _capa != null:
				_capa.queue_redraw()
			if SoundManager != null:
				SoundManager.play_success()
			terminar(clampf(1.0 - penalizacion_error * _errores, 0.2, 1.0))
		else:
			if SoundManager != null:
				SoundManager.play_connect()
	else:
		_errores += 1
		_sel = -1
		if SoundManager != null:
			SoundManager.play_error()

func _punto_izq(i: int) -> Vector2:
	var b: Button = izq[i]
	return b.global_position + Vector2(b.size.x, b.size.y * 0.5) - _capa.global_position

func _punto_der(j: int) -> Vector2:
	var b: Button = der[j]
	return b.global_position + Vector2(0.0, b.size.y * 0.5) - _capa.global_position

func _dibujar() -> void:
	for i in _conexiones:
		_cable(_punto_izq(i), _punto_der(_conexiones[i]), COLORES[i % COLORES.size()])
	if _sel >= 0:
		_cable(_punto_izq(_sel), _capa.get_local_mouse_position(), COLORES[_sel % COLORES.size()])

func _cable(p1: Vector2, p2: Vector2, col: Color) -> void:
	_capa.draw_line(p1, p2, Color(0, 0, 0, 0.85), 16.0, true)   # contorno
	_capa.draw_line(p1, p2, col.darkened(0.3), 12.0, true)      # funda
	_capa.draw_line(p1, p2, col, 7.0, true)                     # núcleo
	_capa.draw_line(p1, p2, col.lightened(0.45), 2.0, true)     # brillo
	for p in [p1, p2]:
		_capa.draw_circle(p, 9.0, Color(0.75, 0.78, 0.82))       # conector metálico
		_capa.draw_circle(p, 6.0, col)

func _puntaje_por_tiempo() -> float:
	return 0.5 * float(_conexiones.size()) / float(maxi(1, izq.size()))