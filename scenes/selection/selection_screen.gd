extends Control

const ESCENA_SIGUIENTE := 'res://scenes/launch/launch.tscn'

@onready var tarjetas: Array = %Tarjetas.get_children()
@onready var contador: Label = %Contador
@onready var descripcion: RichTextLabel = %Descripcion
@onready var boton_despegar: Button = %BotonDespegar

var elegidos: Array = []

func _ready() -> void:
	GameState.reiniciar()
	for t in tarjetas:
		t.tarjeta_toggled.connect(_on_tarjeta_toggled)
		t.tarjeta_enfocada.connect(_mostrar_descripcion)
	boton_despegar.pressed.connect(_on_despegar)
	_actualizar_ui()

func _on_tarjeta_toggled(id: String, activada: bool) -> void:
	if activada:
		elegidos.append(id)
	else:
		elegidos.erase(id)
	_actualizar_ui()

func _actualizar_ui() -> void:
	var lleno := elegidos.size() >= GameState.MAX_MEJORAS
	for t in tarjetas:
		t.disabled = lleno and not t.button_pressed
	contador.text = 'Upgrades: %d / %d' % [elegidos.size(), GameState.MAX_MEJORAS]
	boton_despegar.disabled = elegidos.size() != GameState.MAX_MEJORAS

func _mostrar_descripcion(id: String) -> void:
	var s: Dictionary = GameData.sistemas[id]
	var tec: Dictionary = s.get('tecnologia', {})
	descripcion.text = '[b]%s[/b]  Standard: %s  Upgraded: %s' % [s['nombre'], tec.get('normal', {}).get('nombre', '-'), tec.get('mejorado', {}).get('nombre', '-')]

func _on_despegar() -> void:
	if SoundManager != null:
		SoundManager.play_select()
	GameState.iniciar_partida(elegidos)
	get_tree().change_scene_to_file(ESCENA_SIGUIENTE)
