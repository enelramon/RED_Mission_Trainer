extends AnimatedSprite2D

var _tiempo := 0.0
@export var velocidad_flotacion := 1.6
@export var amplitud_flotacion := 8.0
var _pos_base := Vector2.ZERO

func _ready() -> void:
	play("default")
	_pos_base = position

func _process(delta: float) -> void:
	_tiempo += delta * velocidad_flotacion
	position.y = _pos_base.y + sin(_tiempo) * amplitud_flotacion
	position.x = _pos_base.x + cos(_tiempo * 0.7) * (amplitud_flotacion * 0.4)
