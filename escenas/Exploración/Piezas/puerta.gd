extends Node3D

@export var angulo_apertura: float = 90.0
@export var duracion: float = 0.5

@onready var bisagra: Node3D = $Bisagra

var abierta: bool = false
var animando: bool = false
var giro_cerrado: float


func _ready() -> void:
	giro_cerrado = bisagra.rotation.y


func interactuar() -> void:
	if animando:
		return

	animando = true
	abierta = not abierta

	var giro_destino := giro_cerrado
	if abierta:
		giro_destino += deg_to_rad(angulo_apertura)

	var movimiento := create_tween()
	movimiento.set_trans(Tween.TRANS_SINE)
	movimiento.set_ease(Tween.EASE_IN_OUT)
	movimiento.tween_property(
		bisagra,
		"rotation:y",
		giro_destino,
		duracion
	)

	await movimiento.finished
	animando = false
