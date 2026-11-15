extends Node
## Carga los JSON una sola vez. Nadie más lee archivos.

const RUTA_SISTEMAS := 'res://data/sistemas.json'
const RUTA_EVENTOS := 'res://data/eventos.json'
const RUTA_ALIMENTOS := 'res://data/alimentos.json'

var sistemas: Dictionary = {}   # id -> datos del sistema
var eventos: Array = []         # lista de eventos (cada uno es un Dictionary)
var alimentos: Array = []       # lista de alimentos disponibles

func _init() -> void:
	_cargar_todo()

func _ready() -> void:
	_cargar_todo()

func _cargar_todo() -> void:
	sistemas = _cargar(RUTA_SISTEMAS).get('sistemas', {})
	eventos = _cargar(RUTA_EVENTOS).get('eventos', [])
	alimentos = _cargar(RUTA_ALIMENTOS).get('alimentos', [])

func _cargar(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		push_error('No existe: ' + ruta)
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if datos == null:
		push_error('JSON inválido: ' + ruta)
		return {}
	return datos
