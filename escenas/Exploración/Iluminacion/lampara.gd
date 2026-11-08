extends Node3D

@export_group("Iluminacion")
@export var encendida: bool = true
@export var color_luz: Color = Color(1.0, 0.72, 0.43)
@export_range(0.0, 16.0, 0.1) var intensidad: float = 2.0
@export_range(0.1, 30.0, 0.1) var alcance: float = 7.0
@export_range(0.1, 4.0, 0.1) var atenuacion: float = 1.5
@export var sombras: bool = true
@export_range(0.0, 100.0, 0.5) var brillo_bombilla: float = 100.0

@export_group("Bajadas de tension")
@export var parpadeo: bool = true
@export_range(0.0, 0.2, 0.01) var fluctuacion: float = 0.04
@export_range(0.2, 60.0, 0.1) var intervalo_minimo: float = 4.0
@export_range(0.2, 60.0, 0.1) var intervalo_maximo: float = 10.0
@export_range(0.0, 1.0, 0.01) var tension_minima: float = 0.15
@export_range(0.1, 5.0, 0.1) var duracion_bajada: float = 0.9

@onready var luz: OmniLight3D = $OmniLight3D
var _materiales: Array[StandardMaterial3D] = []
var _azar := RandomNumberGenerator.new()
var _tiempo: float = 0.0
var _espera: float = 0.0
var _tension: float = 1.0
var _bajada: Tween

func _ready() -> void:
	_azar.randomize()
	_tiempo = _azar.randf_range(0.0, 1000.0)
	# Solo duplicamos los materiales emisivos para animar cada lampara por separado.
	for nodo in find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		for superficie in malla.mesh.get_surface_count():
			var original := malla.get_active_material(superficie) as StandardMaterial3D
			if original != null and original.emission_enabled:
				var material := original.duplicate() as StandardMaterial3D
				malla.set_surface_override_material(superficie, material)
				_materiales.append(material)
	_programar_bajada()
	_actualizar(1.0 if encendida else 0.0)

func _process(delta: float) -> void:
	_tiempo += delta
	if not encendida or not parpadeo:
		if _bajada != null and _bajada.is_running():
			_bajada.kill()
		_tension = 1.0
		_actualizar(1.0 if encendida else 0.0)
		return
	_espera -= delta
	if _espera <= 0.0 and (_bajada == null or not _bajada.is_running()):
		_iniciar_bajada()
	var variacion := fluctuacion * (0.65 * sin(_tiempo * 7.3) + 0.35 * sin(_tiempo * 13.7))
	_actualizar(maxf(0.0, _tension * (1.0 + variacion)))

func _programar_bajada() -> void:
	_espera = _azar.randf_range(intervalo_minimo, maxf(intervalo_minimo, intervalo_maximo))

func _iniciar_bajada() -> void:
	_bajada = create_tween()
	# Algunas bajadas comienzan con un corte breve; no es un parpadeo periodico.
	if _azar.randf() < 0.35:
		_bajada.tween_property(self, "_tension", 0.03, 0.04)
		_bajada.tween_property(self, "_tension", 0.8, 0.08)
	var nivel := _azar.randf_range(tension_minima, minf(1.0, tension_minima + 0.25))
	_bajada.tween_property(self, "_tension", nivel, duracion_bajada * 0.2).set_trans(Tween.TRANS_SINE)
	_bajada.tween_interval(duracion_bajada * 0.2)
	_bajada.tween_property(self, "_tension", 1.0, duracion_bajada * 0.6).set_trans(Tween.TRANS_SINE)
	_bajada.tween_callback(_programar_bajada)

func _actualizar(factor: float) -> void:
	luz.visible = encendida
	luz.light_color = color_luz
	luz.light_energy = intensidad * factor
	luz.omni_range = alcance
	luz.omni_attenuation = atenuacion
	luz.shadow_enabled = sombras
	for material in _materiales:
		material.emission = color_luz
		material.emission_energy_multiplier = brillo_bombilla * factor
