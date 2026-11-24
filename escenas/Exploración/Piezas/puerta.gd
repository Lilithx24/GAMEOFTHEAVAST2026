extends Node3D

@export var angulo_apertura: float = 90.0
@export var duracion: float = 0.5
@export var duracion_apertura: float = 1.3

@onready var bisagra: Node3D = $Bisagra
@onready var sonido_apertura: AudioStreamPlayer = $SonidoApertura

var abierta: bool = false
var animando: bool = false
var giro_cerrado: float
var clave_estado: String


func _ready() -> void:
	giro_cerrado = bisagra.rotation.y
	# La escena y la ruta distinguen cada puerta, incluso entre distintos pisos.
	var nivel: Node = self
	while nivel.get_parent() != get_tree().root:
		nivel = nivel.get_parent()
	clave_estado = "%s::%s" % [nivel.scene_file_path, nivel.get_path_to(self)]
	abierta = EstadoPartida.estados_puertas.get(clave_estado, false)
	if abierta:
		bisagra.rotation.y = giro_cerrado + deg_to_rad(angulo_apertura)


func punto_interaccion() -> Vector3:
	return $Bisagra/Puerta/PuntoInteraccion.global_position


func puede_interactuar_con(cuerpo: Node) -> bool:
	return not animando and cuerpo == $Bisagra/Puerta/Cuerpo


func interactuar() -> void:
	if animando:
		return

	animando = true
	abierta = not abierta
	EstadoPartida.estados_puertas[clave_estado] = abierta

	var giro_destino := giro_cerrado
	if abierta:
		giro_destino += deg_to_rad(angulo_apertura)
		sonido_apertura.play()

	var movimiento := create_tween()
	movimiento.set_trans(Tween.TRANS_SINE)
	movimiento.set_ease(Tween.EASE_IN_OUT)
	movimiento.tween_property(
		bisagra,
		"rotation:y",
		giro_destino,
		duracion_apertura if abierta else duracion
	)

	await movimiento.finished
	animando = false
