extends SceneTree

func _init() -> void:
	print("=== GENERANDO EFECTOS DE SONIDO 8-BIT ===")
	_generar_todos()
	quit(0)

func _generar_todos() -> void:
	var sr := 44100
	
	# 1. select.wav - Sonido táctil muy satisfactorio para botones de selección
	var sel_samples := PackedFloat32Array()
	var dur_sel := 0.09
	var n_sel := int(dur_sel * sr)
	sel_samples.resize(n_sel)
	for i in n_sel:
		var t := float(i) / sr
		var env := exp(-t * 40.0) if t > 0.003 else (t / 0.003)
		var freq := 560.0 + 380.0 * (1.0 - exp(-t * 50.0))
		var onda := sin(2.0 * PI * freq * t) * 0.7 + sin(4.0 * PI * freq * t) * 0.25 + (1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0) * 0.15
		sel_samples[i] = onda * env * 0.75
	_guardar_wav(sel_samples, "res://audio/select.wav", sr)

	# 2. click.wav - Clic 8-bit simple
	var clk_samples := PackedFloat32Array()
	var dur_clk := 0.04
	var n_clk := int(dur_clk * sr)
	clk_samples.resize(n_clk)
	for i in n_clk:
		var t := float(i) / sr
		var env := exp(-t * 65.0)
		var freq := 720.0 - 200.0 * (t / dur_clk)
		var onda := 1.0 if sin(2.0 * PI * freq * t) > 0.0 else -1.0
		clk_samples[i] = onda * env * 0.4
	_guardar_wav(clk_samples, "res://audio/click.wav", sr)

	# 3. connect.wav - Conexión de cable espacial
	var con_samples := PackedFloat32Array()
	var dur_con := 0.14
	var n_con := int(dur_con * sr)
	con_samples.resize(n_con)
	for i in n_con:
		var t := float(i) / sr
		var env := 1.0 - (t / dur_con)
		var freq := 380.0 + 1100.0 * (t / dur_con)
		var onda := 1.0 if sin(2.0 * PI * freq * t + 0.3 * sin(12.0 * PI * freq * t)) > 0.1 else -1.0
		con_samples[i] = onda * env * 0.45
	_guardar_wav(con_samples, "res://audio/connect.wav", sr)

	# 4. laser.wav - Acierto en zona de barra / láser espacial
	var las_samples := PackedFloat32Array()
	var dur_las := 0.13
	var n_las := int(dur_las * sr)
	las_samples.resize(n_las)
	for i in n_las:
		var t := float(i) / sr
		var env := exp(-t * 22.0)
		var freq := 1350.0 * exp(-t * 16.0) + 240.0
		var onda := 1.0 if sin(2.0 * PI * freq * t) > 0.0 else -1.0
		las_samples[i] = onda * env * 0.48
	_guardar_wav(las_samples, "res://audio/laser.wav", sr)

	# 5. error.wav - Fallo / error retro
	var err_samples := PackedFloat32Array()
	var dur_err := 0.20
	var n_err := int(dur_err * sr)
	err_samples.resize(n_err)
	for i in n_err:
		var t := float(i) / sr
		var env := exp(-t * 14.0)
		var freq := 180.0 - 60.0 * (t / dur_err) + 25.0 * sin(70.0 * PI * t)
		var onda := 1.0 if sin(2.0 * PI * freq * t) > 0.0 else -1.0
		err_samples[i] = onda * env * 0.5
	_guardar_wav(err_samples, "res://audio/error.wav", sr)

	# 6. success.wav - Fanfarria de victoria minijuego (arpegio espacial 8 bit)
	var suc_samples := PackedFloat32Array()
	var dur_suc := 0.38
	var n_suc := int(dur_suc * sr)
	suc_samples.resize(n_suc)
	var notas := [523.25, 659.25, 783.99, 1046.50] # Do, Mi, Sol, Do alto
	for i in n_suc:
		var t := float(i) / sr
		var paso := clampi(int(t / 0.08), 0, 3)
		var t_paso := fmod(t, 0.08)
		var freq: float = notas[paso]
		var env: float
		if paso < 3:
			env = exp(-t_paso * 22.0)
		else:
			var t_final := t - 0.24
			env = exp(-t_final * 9.0)
		var onda := 1.0 if sin(2.0 * PI * freq * t) > 0.1 else -1.0
		# Añadir armónico suave para que suene brillante
		var onda2 := sin(4.0 * PI * freq * t) * 0.25
		suc_samples[i] = (onda * 0.45 + onda2) * env * 0.65
	_guardar_wav(suc_samples, "res://audio/success.wav", sr)

	# 7. step_1 .. step_4 - Tonos de secuencia 8-bit
	var notas_sec := [440.0, 554.37, 659.25, 880.0]
	for k in 4:
		var st_samples := PackedFloat32Array()
		var dur_st := 0.12
		var n_st := int(dur_st * sr)
		st_samples.resize(n_st)
		var freq_st: float = notas_sec[k]
		for i in n_st:
			var t := float(i) / sr
			var env := exp(-t * 22.0)
			var onda := 1.0 if sin(2.0 * PI * freq_st * t) > 0.0 else -1.0
			st_samples[i] = onda * env * 0.45
		_guardar_wav(st_samples, "res://audio/step_%d.wav" % (k + 1), sr)

func _guardar_wav(muestras: PackedFloat32Array, ruta: String, sample_rate: int) -> void:
	var n := muestras.size()
	var bytes_datos := n * 2
	var buffer := PackedByteArray()
	buffer.resize(44 + bytes_datos)
	
	# RIFF header
	buffer.encode_u32(0, 0x46464952) # "RIFF"
	buffer.encode_u32(4, 36 + bytes_datos)
	buffer.encode_u32(8, 0x45564157) # "WAVE"
	
	# fmt subchunk
	buffer.encode_u32(12, 0x20746D66) # "fmt "
	buffer.encode_u32(16, 16)
	buffer.encode_u16(20, 1) # PCM
	buffer.encode_u16(22, 1) # Mono
	buffer.encode_u32(24, sample_rate)
	buffer.encode_u32(28, sample_rate * 2)
	buffer.encode_u16(32, 2)
	buffer.encode_u16(34, 16)
	
	# data subchunk
	buffer.encode_u32(36, 0x61746164) # "data"
	buffer.encode_u32(40, bytes_datos)
	
	for i in n:
		var s := clampf(muestras[i], -1.0, 1.0)
		var val_i := int(s * 32767.0)
		buffer.encode_s16(44 + i * 2, val_i)
		
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f != null:
		f.store_buffer(buffer)
		f.close()
		print("  -> Generado: ", ruta)
