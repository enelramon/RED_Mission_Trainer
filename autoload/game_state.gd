extends Node
## Única fuente de verdad. Los recursos van de 0 a 100.

signal recurso_cambio(id: String, valor: float, delta: float, motivo: String)
signal recurso_agotado(id: String)
signal turno_cambio(numero: int)
signal robot_dice(texto: String)
signal mision_terminada(resultado: int)
signal estado_evento_cambio()

enum Resultado { COMPLETADA, ABORTADA }

const TOTAL_TURNOS := 5
const MAX_MEJORAS := 2
const INTERVALO_EVENTOS := 15.0
const SISTEMAS := ['energia', 'aire', 'agua', 'alimentos', 'proteccion']
const ABORTAN := ['energia', 'aire', 'agua', 'alimentos', 'proteccion'] # el ánimo no aborta (por decidir)

var recursos: Dictionary = {}
var mejoras: Array = []
var turno: int = 0
var mazo: Array = []
var historial: Array = []
var comidas: Array = []
var resultado_final: int = -1
var causa_aborto: String = ''
var tiempo_proximo_evento: float = INTERVALO_EVENTOS
var evento_en_curso: String = ''
var _agotados: Array = []
var _terminada := false
var _reproductor_alarma: AudioStreamPlayer = null
var _wav_alarma_estacion: AudioStreamWAV = null
var _wav_alarma_clima: AudioStreamWAV = null

func _ready() -> void:
	if not InputMap.has_action('interactuar'):
		InputMap.add_action('interactuar')
	if InputMap.action_get_events('interactuar').is_empty():
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.physical_keycode = KEY_E
		InputMap.action_add_event('interactuar', ev)
	_inicializar_audio_alarma()
	recurso_agotado.connect(_on_recurso_agotado)
	reiniciar()

func _inicializar_audio_alarma() -> void:
	_reproductor_alarma = AudioStreamPlayer.new()
	_reproductor_alarma.name = 'ReproductorAlarma'
	_reproductor_alarma.volume_db = -8.0 # Volumen suave y agradable
	add_child(_reproductor_alarma)
	# Sonido suave tipo campana espacial armónica (C5 -> G5)
	_wav_alarma_estacion = _crear_sonido_agradable(523.25, 783.99, 0.85)
	# Sonido ambiental suave para clima (D5 -> A4 con eco sutil)
	_wav_alarma_clima = _crear_sonido_agradable(587.33, 440.00, 1.10)

func _crear_sonido_agradable(frec_1: float, frec_2: float, duracion: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var total_samples := int(mix_rate * duracion)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	var tiempo_cambio := duracion * 0.38
	var fase := 0.0

	for i in total_samples:
		var t := float(i) / float(mix_rate)
		var frec: float
		var env: float

		if t < tiempo_cambio:
			frec = frec_1
			var t_local := t
			var ataque := clampf(t_local / 0.012, 0.0, 1.0)
			var caida := exp(-4.5 * t_local)
			env = ataque * caida
		else:
			frec = frec_2
			var t_local := t - tiempo_cambio
			var ataque := clampf(t_local / 0.012, 0.0, 1.0)
			var caida := exp(-3.8 * t_local)
			env = ataque * caida

		fase += TAU * frec / float(mix_rate)
		# Onda senoidal pura y armónico cálido al 20%, sin distorsiones agresivas
		var onda := sin(fase) * 0.80 + sin(fase * 2.0) * 0.20
		var muestra := int(clampf(onda * env * 0.38, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, muestra)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func sonar_alarma(tipo: String = 'estacion') -> void:
	if _reproductor_alarma == null:
		return
	_reproductor_alarma.stream = _wav_alarma_clima if tipo == 'clima' else _wav_alarma_estacion
	_reproductor_alarma.play()

func actualizar_estado_evento(tiempo_restante: float, nombre_evento: String = '') -> void:
	tiempo_proximo_evento = maxf(0.0, tiempo_restante)
	evento_en_curso = nombre_evento
	estado_evento_cambio.emit()

func reiniciar() -> void:
	recursos.clear()
	for id in SISTEMAS:
		recursos[id] = 100.0
	recursos['animo'] = 100.0
	mejoras = []
	turno = 0
	mazo = []
	historial = []
	comidas = []
	resultado_final = -1
	causa_aborto = ''
	tiempo_proximo_evento = INTERVALO_EVENTOS
	evento_en_curso = ''
	_agotados = []
	_terminada = false

func iniciar_partida(mejoras_elegidas: Array) -> void:
	reiniciar()
	mejoras = mejoras_elegidas.duplicate()

func esta_mejorado(id: String) -> bool:
	return id in mejoras

func es_mejorado(id: String) -> bool:
	return id in mejoras

func tiene_mejora(id: String) -> bool:
	return id in mejoras

func nivel(id: String) -> String:
	return 'mejorado' if esta_mejorado(id) else 'normal'

func partida_terminada() -> bool:
	return _terminada

func decir(texto: String) -> void:
	if texto != '':
		robot_dice.emit(texto)

# --- Recursos ---------------------------------------------------------
func cambiar(id: String, delta: float, motivo: String = '') -> void:
	if _terminada or not recursos.has(id):
		return
	var antes: float = recursos[id]
	recursos[id] = clampf(antes + delta, 0.0, 100.0)
	recurso_cambio.emit(id, recursos[id], recursos[id] - antes, motivo)
	if recursos[id] <= 0.0 and not (id in _agotados):
		_agotados.append(id)
		recurso_agotado.emit(id) # una sola vez por recurso

# --- Turnos -----------------------------------------------------------
func empezar_turno() -> void:
	turno += 1
	turno_cambio.emit(turno)

func terminar_turno() -> void:
	for id in recursos:
		var consumo: Dictionary = GameData.sistemas.get(id, {}).get('consumo_turno', {})
		cambiar(id, consumo.get(nivel(id), 0.0), 'Sol consumption')
	_cascadas()
	if not _terminada and turno >= TOTAL_TURNOS:
		_terminar(Resultado.COMPLETADA)

func _cascadas() -> void:
	# 1. Energy -> Oxygen & Food (MOXIE at ~798 °C and Veggie LED lights require high power)
	if recursos['energia'] < 35.0:
		if esta_mejorado('aire'):
			cambiar('aire', -4.0, 'Power deficit for MOXIE electrolysis')
		if esta_mejorado('alimentos'):
			cambiar('alimentos', -4.0, 'Power deficit for Veggie/APH LED growth lights')
	
	# 2. Water <-> Oxygen & Food (O2 electrolysis, crop irrigation, and ration rehydration)
	if recursos['agua'] < 30.0:
		cambiar('aire', -3.0, 'Low water level for O₂ electrolysis generation')
		if esta_mejorado('alimentos'):
			cambiar('alimentos', -5.0, 'Water deficit for hydroponic crop irrigation')
		else:
			cambiar('alimentos', -3.0, 'Water deficit for meal ration rehydration')
	
	# 3. Shielding -> Morale (Stress from radiation 0.64 mSv/day and toxic regolith containment)
	if recursos['proteccion'] < 35.0:
		cambiar('animo', -6.0, 'Crew stress from radiation exposure and toxic perchlorate dust')

# --- Eventos ----------------------------------------------------------
func resolver_variante(evento: Dictionary) -> Dictionary:
	# Si el evento tiene 'variantes', usa la del nivel de su sistema principal.
	var resuelto := evento.duplicate(true)
	var extra: Dictionary = evento.get('variantes', {}).get(nivel(evento['sistema']), {})
	resuelto.merge(extra, true)
	return resuelto

func aplicar_evento(evento: Dictionary, puntaje: float) -> void:
	var antes := recursos.duplicate()
	var efectos: Dictionary = evento.get('efectos', {})
	for id in efectos:
		var segun: String = efectos[id].get('segun', id) # de qué sistema depende la variante
		var delta: float = efectos[id].get(nivel(segun), 0.0)
		if delta < 0.0:
			delta *= 1.0 - 0.5 * clampf(puntaje, 0.0, 1.0) # jugar bien reduce el daño
		cambiar(id, delta, evento['nombre'])
	var cambios := {}
	for id in recursos:
		cambios[id] = recursos[id] - antes[id]
	historial.append({'turno': turno, 'evento': evento['id'], 'nombre': evento['nombre'], 'puntaje': puntaje, 'cambios': cambios})

func registrar_comida(comida_input) -> void:
	var item_id := ""
	if typeof(comida_input) == TYPE_ARRAY and not comida_input.is_empty():
		item_id = str(comida_input[0])
	elif typeof(comida_input) == TYPE_STRING:
		item_id = comida_input
	elif typeof(comida_input) == TYPE_DICTIONARY:
		item_id = comida_input.get('id', '')
	
	var info_plato: Dictionary = {}
	for a in GameData.alimentos:
		if a.get('id', '') == item_id:
			info_plato = a
			break
	if info_plato.is_empty():
		info_plato = {"id": item_id, "nombre": item_id.capitalize(), "tipo": "Ración", "animo_base": 3}
	
	var repetido := false
	if not comidas.is_empty():
		var ultima = comidas.back()
		var id_ant := ""
		if typeof(ultima) == TYPE_DICTIONARY:
			id_ant = ultima.get('id', '')
		elif typeof(ultima) == TYPE_ARRAY and not ultima.is_empty():
			id_ant = str(ultima[0])
		else:
			id_ant = str(ultima)
		if id_ant == item_id and item_id != "":
			repetido = true
			
	comidas.append(info_plato)
	
	if repetido:
		cambiar('animo', -6.0, 'Repetitive ration menu fatigue')
		decir("🍽️ Marquitos: 'The crew suffers menu fatigue from consecutive duplicate rations! (Morale -6%)'")
	else:
		var boost: float = float(info_plato.get('animo_base', 4))
		if esta_mejorado('alimentos') and info_plato.get('tipo', '') == 'Fresh Local Harvest':
			boost += 3.0
		cambiar('animo', boost, 'Nutritional variety')
		decir("🍽️ Marquitos: 'Selected ration: %s. Optimal nutritional diversity! (Morale +%d%%)'" % [info_plato.get('nombre', item_id), int(boost)])

# --- Final ------------------------------------------------------------
func _on_recurso_agotado(id: String) -> void:
	if id in ABORTAN:
		_terminar(Resultado.ABORTADA, id)

func _terminar(res: int, causa: String = '') -> void:
	if _terminada:
		return
	_terminada = true
	resultado_final = res
	causa_aborto = causa
	mision_terminada.emit(res)

func resumen() -> Dictionary:
	var salieron := historial.map(func(h): return h['evento'])
	var no_salieron := GameData.eventos.filter(func(e): return not (e['id'] in salieron))
	return {
		'mejoras': mejoras,
		'resultado': resultado_final,
		'causa_aborto': causa_aborto,
		'recursos_finales': recursos.duplicate(),
		'historial': historial,
		'comidas': comidas,
		'eventos_no_salieron': no_salieron,
	}


