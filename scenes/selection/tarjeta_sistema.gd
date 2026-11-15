extends Button
class_name TarjetaSistema

signal tarjeta_toggled(id: String, activada: bool)
signal tarjeta_enfocada(id: String)

@export var sistema_id: String = 'energia'

func _ready() -> void:
	toggle_mode = true
	text = GameData.sistemas[sistema_id]['nombre']
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_enfocada)
	focus_entered.connect(_on_enfocada)

func _on_toggled(activada: bool) -> void:
	if SoundManager != null:
		SoundManager.play_select()
	tarjeta_toggled.emit(sistema_id, activada)

func _on_enfocada() -> void:
	tarjeta_enfocada.emit(sistema_id)
