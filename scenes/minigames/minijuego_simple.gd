extends Minijuego
## Base de todos los minijuegos simples.
## LOS GRÁFICOS SON NODOS DE LA ESCENA: ábrela en Godot y cambia colores, tamaños,
## textos o reemplaza un ColorRect por un TextureRect con tu imagen (mantén el mismo nombre).
## Nodos opcionales que usa esta base: %Titulo (Label), %Instrucciones (Label), %Tiempo (ProgressBar).

@export var tiempo_limite: float = 8.0

var datos: Dictionary = {}
var tiempo_restante: float = 0.0
var _cerrado := false

func _ready() -> void:
	var barra := get_node_or_null('%Tiempo')
	if barra is ProgressBar:
		var st_bg := StyleBoxFlat.new()
		st_bg.bg_color = Color(0.08, 0.12, 0.18, 0.95)
		st_bg.set_corner_radius_all(5)
		barra.add_theme_stylebox_override("background", st_bg)

		var st_fill := StyleBoxFlat.new()
		st_fill.bg_color = Color(0.3, 0.85, 1.0, 1.0)
		st_fill.set_corner_radius_all(5)
		barra.add_theme_stylebox_override("fill", st_fill)

func iniciar(evento: Dictionary) -> void:
	datos = evento
	tiempo_restante = tiempo_limite
	var titulo := get_node_or_null('%Titulo')
	if titulo is Label and evento.has('nombre'):
		titulo.text = str(evento['nombre'])
	_empezar()

## Cada minijuego prepara su ronda aquí.
func _empezar() -> void:
	pass

## Puntaje que se entrega si se acaba el tiempo.
func _puntaje_por_tiempo() -> float:
	return 0.0

## Lógica por frame de cada minijuego.
func _actualizar(_delta: float) -> void:
	pass

func _process(delta: float) -> void:
	if _cerrado:
		return
	tiempo_restante -= delta
	var barra := get_node_or_null('%Tiempo')
	if barra is Range:
		barra.value = 100.0 * maxf(tiempo_restante, 0.0) / tiempo_limite
	if tiempo_restante <= 0.0:
		terminar(_puntaje_por_tiempo())
		return
	_actualizar(delta)

func terminar(puntaje: float) -> void:
	if _cerrado:
		return
	_cerrado = true
	finalizar(puntaje)

## Tecla "de acción" común: Espacio, Enter o E.
func es_accion(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]
	return false

