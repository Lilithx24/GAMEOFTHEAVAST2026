extends CanvasLayer

signal finalizada

@export_file("*.tscn") var escena_combate: String = "res://escenas/Combate.tscn"
@export_group("Tiempos")
@export_range(0.05, 3.0, 0.05) var duracion_apagado: float = 0.55
@export_range(0.0, 2.0, 0.05) var pausa_oscura: float = 0.2
@export_range(0.05, 3.0, 0.05) var duracion_encendido: float = 0.65
@export_group("Camara y efectos")
@export var parpadeo_inicial: bool = true
@export_range(0.0, 12.0, 0.5) var acercamiento_fov: float = 5.0
@export_range(-3.0, 3.0, 0.1) var inclinacion_grados: float = 0.8
@export_range(0.0, 1.0, 0.05) var intensidad_vineta: float = 0.7

@onready var negro: ColorRect = $Pantalla/Negro
@onready var vineta: ColorRect = $Pantalla/Vineta
@onready var sfx_apagon: AudioStreamPlayer = $Apagon
@onready var sfx_encendido: AudioStreamPlayer = $Encendido

var en_curso: bool = false
var _luces: Array[Light3D] = []
var _energias: Array[float] = []
var _emisivos: Array[BaseMaterial3D] = []
var _brillos: Array[float] = []


func _input(_event: InputEvent) -> void:
	if en_curso:
		get_viewport().set_input_as_handled()


func iniciar(nivel: Node, camara: Camera3D, musica: AudioStreamPlayer3D, enemigo: Node3D = null) -> void:
	if en_curso:
		return
	en_curso = true
	var pausa_anterior := get_tree().paused
	get_tree().paused = true
	_recoger_luces(nivel)
	var fov_original := camara.fov
	var giro_original := camara.rotation.z
	var volumen_original := musica.volume_db if is_instance_valid(musica) else 0.0
	negro.color.a = 0.0
	vineta.material.set_shader_parameter("intensidad", 0.0)
	show()
	if is_instance_valid(enemigo) and enemigo.has_method("abalanzarse"):
		await enemigo.call("abalanzarse", camara)
	vineta.material.set_shader_parameter("intensidad", intensidad_vineta)
	sfx_apagon.play()

	if parpadeo_inicial:
		var parpadeo := create_tween()
		parpadeo.tween_method(_aplicar_luces, 1.0, 0.2, 0.07)
		parpadeo.tween_method(_aplicar_luces, 0.2, 0.65, 0.1)
		await parpadeo.finished

	var apagar := create_tween().set_parallel(true)
	apagar.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	apagar.tween_method(_aplicar_luces, 0.65 if parpadeo_inicial else 1.0, 0.0, duracion_apagado)
	apagar.tween_property(negro, "color:a", 1.0, duracion_apagado)
	apagar.tween_property(camara, "fov", maxf(1.0, fov_original - acercamiento_fov), duracion_apagado)
	apagar.tween_property(camara, "rotation:z", giro_original + deg_to_rad(inclinacion_grados), duracion_apagado)
	if is_instance_valid(musica):
		apagar.tween_property(musica, "volume_db", -60.0, duracion_apagado)
	await apagar.finished
	await get_tree().create_timer(maxf(0.01, pausa_oscura)).timeout

	var error := get_tree().change_scene_to_file(escena_combate)
	if error != OK:
		push_error("No se pudo cargar el combate: %s" % error_string(error))
		_aplicar_luces(1.0)
		camara.fov = fov_original
		camara.rotation.z = giro_original
		if is_instance_valid(musica):
			musica.volume_db = volumen_original
		_terminar(pausa_anterior)
		return
	await get_tree().scene_changed
	# Ya existe el combate, pero permanece tapado y pausado durante el encendido.
	_soltar_referencias()
	sfx_encendido.play()
	var encender := create_tween().set_parallel(true)
	encender.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	encender.tween_property(negro, "color:a", 0.0, duracion_encendido)
	encender.tween_method(_aplicar_vineta, intensidad_vineta, 0.0, duracion_encendido)
	await encender.finished
	_terminar(pausa_anterior)


func _recoger_luces(nivel: Node) -> void:
	_soltar_referencias()
	for nodo in nivel.find_children("*", "Light3D", true, false):
		_luces.append(nodo)
		_energias.append(nodo.light_energy)
	# Las bombillas también se apagan: no basta con apagar la luz que proyectan.
	for nodo in nivel.find_children("*", "MeshInstance3D", true, false):
		if nodo.mesh == null:
			continue
		for superficie in nodo.mesh.get_surface_count():
			var material = nodo.get_active_material(superficie)
			if material is BaseMaterial3D and material.emission_enabled and not _emisivos.has(material):
				_emisivos.append(material)
				_brillos.append(material.emission_energy_multiplier)


func _aplicar_luces(factor: float) -> void:
	for i in _luces.size():
		if is_instance_valid(_luces[i]):
			_luces[i].light_energy = _energias[i] * factor
	for i in _emisivos.size():
		_emisivos[i].emission_energy_multiplier = _brillos[i] * factor


func _aplicar_vineta(factor: float) -> void:
	vineta.material.set_shader_parameter("intensidad", factor)


func _soltar_referencias() -> void:
	# Restaurar recursos compartidos evita dejar materiales apagados al regresar al piso.
	for i in _emisivos.size():
		_emisivos[i].emission_energy_multiplier = _brillos[i]
	_luces.clear()
	_energias.clear()
	_emisivos.clear()
	_brillos.clear()


func _terminar(pausa_anterior: bool) -> void:
	_soltar_referencias()
	negro.color.a = 0.0
	_aplicar_vineta(0.0)
	hide()
	get_tree().paused = pausa_anterior
	en_curso = false
	finalizada.emit()
