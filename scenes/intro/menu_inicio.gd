extends Control

const ESCENA_SIGUIENTE := 'res://scenes/launch/launch.tscn'
const FONT_NSAC := preload("res://fonts/SHPinscher-Regular.otf")
const TEX_BOTON_BARRA := preload("res://Fotos/Separados/Iconos/boton_barra.png")

@onready var textura_fondo: TextureRect = %TexturaFondo
@onready var btn_despegar: Button = %BotonDespegar
@onready var btn_jugar: Button = %BotonDespegar
@onready var btn_guia: Button = %BotonGuia
@onready var btn_salir: Button = %BotonSalir
@onready var panel_guia: PanelContainer = %PanelGuia
@onready var btn_cerrar_guia: Button = %BotonCerrarGuia
@onready var lbl_marquitos: Label = %LabelMarquitos
@onready var icono_marquitos: TextureRect = %IconoMarquitos
@onready var tarjetas: Array = %Tarjetas.get_children()
@onready var contador: Label = %Contador
@onready var descripcion: RichTextLabel = %Descripcion

var elegidos: Array = []
var _tiempo := 0.0

func _ready() -> void:
	GameState.reiniciar()
	_cargar_fondo_dinamico()

	for t in tarjetas:
		if t is TarjetaSistema:
			t.tarjeta_toggled.connect(_on_tarjeta_toggled)
			t.tarjeta_enfocada.connect(_mostrar_descripcion)

	btn_despegar.pressed.connect(_on_despegar)
	btn_guia.pressed.connect(func(): panel_guia.visible = true)
	btn_cerrar_guia.pressed.connect(func(): panel_guia.visible = false)
	btn_salir.pressed.connect(func(): get_tree().quit())
	panel_guia.visible = false

	_mostrar_descripcion("energia")
	_actualizar_ui()

func _cargar_fondo_dinamico() -> void:
	if textura_fondo == null:
		return
	const RUTA := "res://Fotos/fondo de inicio nasa.png"
	if ResourceLoader.exists(RUTA):
		var tex = load(RUTA)
		if tex is Texture2D:
			textura_fondo.texture = tex
			return
	var img := Image.load_from_file(ProjectSettings.globalize_path(RUTA))
	if img != null and not img.is_empty():
		textura_fondo.texture = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	_tiempo += delta * 2.8
	if icono_marquitos != null:
		icono_marquitos.position.y = 8.0 + sin(_tiempo) * 4.0

func _on_tarjeta_toggled(id: String, activada: bool) -> void:
	if activada:
		if not elegidos.has(id):
			elegidos.append(id)
	else:
		elegidos.erase(id)
	_actualizar_ui()
	_mostrar_descripcion(id)

func _actualizar_ui() -> void:
	var lleno := elegidos.size() >= GameState.MAX_MEJORAS
	for t in tarjetas:
		if t is TarjetaSistema:
			t.actualizar_bloqueo(lleno and not t.button_pressed)

	if contador != null:
		contador.text = "Selected Upgrades: %d / %d" % [elegidos.size(), GameState.MAX_MEJORAS]
		if lleno:
			contador.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			contador.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))

	btn_despegar.disabled = elegidos.size() != GameState.MAX_MEJORAS
	_estilar_boton_despegar(not btn_despegar.disabled)

	if lbl_marquitos != null:
		if elegidos.is_empty():
			lbl_marquitos.text = "Marquitos (AI Assistant): 'Welcome, cadet. Select 2 vital life-support systems to equip with advanced technology.'"
		elif elegidos.size() == 1:
			var nom_primero = GameData.sistemas.get(elegidos[0], {}).get('nombre', elegidos[0])
			lbl_marquitos.text = "Marquitos: 'Excellent! You upgraded %s. Select 1 more upgrade to complete spaceship outfitting.'" % nom_primero
		else:
			lbl_marquitos.text = "Marquitos: 'All systems green! Engineering modules calibrated. Press LAUNCH to initiate the voyage to Mars.'"

func _estilar_boton_despegar(activo: bool) -> void:
	var sb := StyleBoxTexture.new()
	sb.texture = TEX_BOTON_BARRA
	sb.texture_margin_left = 6.0
	sb.texture_margin_right = 6.0
	sb.texture_margin_top = 2.0
	sb.texture_margin_bottom = 2.0
	if activo:
		sb.modulate_color = Color(0.2, 0.85, 0.45, 0.98)
		btn_despegar.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.modulate_color = Color(0.25, 0.30, 0.40, 0.6)
		btn_despegar.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 0.8))
	btn_despegar.add_theme_stylebox_override("normal", sb)

func _mostrar_descripcion(id: String) -> void:
	if descripcion == null or not GameData.sistemas.has(id):
		return
	var s: Dictionary = GameData.sistemas[id]
	var tec: Dictionary = s.get('tecnologia', {})
	var t_norm: Dictionary = tec.get('normal', {})
	var t_mej: Dictionary = tec.get('mejorado', {})
	var cons: Dictionary = s.get('consumo_turno', {})

	var bb := "[font_size=18][b]%s System[/b][/font_size]\n" % s.get('nombre', id.capitalize())
	bb += "[color=#ffbb77]● Standard:[/color] %s (Drain: %d%%/sol)\n" % [
		t_norm.get('nombre', 'Basic'),
		int(cons.get('normal', -8))
	]
	bb += "[color=#77ffaa]★ Advanced Tech:[/color] %s (Drain: %d%%/sol) — [i]%s[/i]" % [
		t_mej.get('nombre', 'Upgraded'),
		int(cons.get('mejorado', -3)),
		t_mej.get('dato', '')
	]
	descripcion.text = bb

func _on_despegar() -> void:
	GameState.iniciar_partida(elegidos)
	get_tree().change_scene_to_file(ESCENA_SIGUIENTE)
