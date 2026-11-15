extends Control

const ESCENA_BASE := 'res://Animacion/node_22d.tscn'
const ESCENA_FALLBACK := 'res://scenes/base/base.tscn'

@onready var nave: AnimatedSprite2D = $ContenedorNave/NaveAnimada

var _cambiando := false

func _ready() -> void:
	if nave != null:
		nave.play("default")
		_centrar_nave()
		get_viewport().size_changed.connect(_centrar_nave)

	if SoundManager != null:
		SoundManager.play_launch()

	# Tras reproducirse la animación, continuar a la base
	get_tree().create_timer(2.4).timeout.connect(_ir_a_base)

func _centrar_nave() -> void:
	if nave != null:
		var v_size := get_viewport_rect().size
		nave.position = v_size * 0.5
		var factor: float = maxf(v_size.x / 582.0, v_size.y / 357.0) * 0.92
		nave.scale = Vector2(factor, factor)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		_ir_a_base()

func _ir_a_base() -> void:
	if _cambiando:
		return
	_cambiando = true
	var destino := ESCENA_BASE if ResourceLoader.exists(ESCENA_BASE) else ESCENA_FALLBACK
	get_tree().change_scene_to_file(destino)
