class_name Minijuego
extends Control
## Los minijuegos empiezan con iniciar() y terminan con finalizar().

signal terminado(puntaje: float)   # 0.0 = fallo total, 1.0 = perfecto

func iniciar(_evento: Dictionary) -> void:
	pass   # cada minijuego lo implementa

func finalizar(puntaje: float) -> void:
	terminado.emit(clampf(puntaje, 0.0, 1.0))
	queue_free()
