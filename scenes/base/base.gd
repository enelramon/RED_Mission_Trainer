extends Node2D

const ESCENA_FINAL := 'res://scenes/end/summary.tscn'

func _enter_tree() -> void:
	# Solo para probar base.tscn con F6: si no vienes de la selección, usa mejoras de prueba.
	if GameState.mejoras.is_empty():
		GameState.iniciar_partida(['energia', 'agua'])

func _ready() -> void:
	GameState.mision_terminada.connect(_on_mision_terminada)

func _on_mision_terminada(_resultado: int) -> void:
	await get_tree().create_timer(1.5).timeout # deja ver el último cambio
	get_tree().change_scene_to_file(ESCENA_FINAL)
