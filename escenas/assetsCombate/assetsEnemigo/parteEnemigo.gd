class_name ParteEnemigo
extends Sprite2D

var vidaMax: int
var vidaActual: int
var vital: bool
var tags: Array[String]
var estados: Array[String]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func sufrirDmg(damage: int):
	var nuevaVida = setVidaActual(vidaActual - damage)
	print("vida restante: ", nuevaVida)

func setVidaActual(vida: int) -> int:
	vidaActual = clampi(vida, 0, vidaMax) #Esta mierda es pa que no baje de 0
	return vidaActual
