extends Node
## Gestor de efectos de sonido espaciales (8-bit) y de interfaz

const SND_SELECT = preload("res://audio/select.wav")
const SND_CLICK = preload("res://audio/click.wav")
const SND_CONNECT = preload("res://audio/connect.wav")
const SND_LASER = preload("res://audio/laser.wav")
const SND_ERROR = preload("res://audio/error.wav")
const SND_SUCCESS = preload("res://audio/success.wav")
const SND_ROCKET = preload("res://audio/rocket_launch.wav")
const SND_STEPS: Array = [
	preload("res://audio/step_1.wav"),
	preload("res://audio/step_2.wav"),
	preload("res://audio/step_3.wav"),
	preload("res://audio/step_4.wav"),
]

var _reproductores: Array[AudioStreamPlayer] = []
const MAX_CANALES := 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in MAX_CANALES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_reproductores.append(p)

func _reproducir(stream: AudioStream, volumen_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	for p in _reproductores:
		if not p.playing:
			p.stream = stream
			p.volume_db = volumen_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	# Si todos están ocupados, usar el primero
	var primero := _reproductores[0]
	primero.stream = stream
	primero.volume_db = volumen_db
	primero.pitch_scale = pitch_scale
	primero.play()

## Sonido satisfactorio al pulsar botones de selección y mejoras
func play_select() -> void:
	_reproducir(SND_SELECT, 1.0, randf_range(0.98, 1.02))

## Clic retro simple
func play_click() -> void:
	_reproducir(SND_CLICK, -1.0, randf_range(0.95, 1.05))

## Conexión exitosa de cable
func play_connect() -> void:
	_reproducir(SND_CONNECT, 0.0, randf_range(0.98, 1.02))

## Láser / acierto en barra de zona
func play_laser() -> void:
	_reproducir(SND_LASER, 0.0, randf_range(0.97, 1.03))

## Error / buzzer retro
func play_error() -> void:
	_reproducir(SND_ERROR, 0.5, randf_range(0.96, 1.02))

## Victoria en minijuego / fanfarria espacial
func play_success() -> void:
	_reproducir(SND_SUCCESS, 1.5, 1.0)

## Notas para secuencia de memoria
func play_step(indice: int) -> void:
	var idx := clampi(indice, 0, SND_STEPS.size() - 1)
	_reproducir(SND_STEPS[idx], 0.5, 1.0)

## Sonido de despegue / nave espacial acelerando
func play_launch() -> void:
	_reproducir(SND_ROCKET, 2.0, 1.0)

