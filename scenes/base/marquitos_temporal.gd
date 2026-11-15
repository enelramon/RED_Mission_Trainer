extends Label
## Robot temporal: solo muestra lo que dice GameState.robot_dice.

func _ready() -> void:
	GameState.robot_dice.connect(_on_robot_dice)

func _on_robot_dice(texto: String) -> void:
	text = texto
