class_name Personaje
extends Node

var vidaMax: int = 100
var vidaActual: int
@onready var barra_vida: ProgressBar = $ProgressBarJ


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func actualizar_barra() -> void:
	barra_vida.max_value = vidaMax
	barra_vida.value = vidaActual


func sufrirDmg(damage: int):
	var nuevaVida = setVidaActual(vidaActual - damage)
	print("vida restante: ", nuevaVida)

func setVidaActual(vida: int) -> int:
	vidaActual = clampi(vida, 0, vidaMax) #Esta mierda es pa que no baje de 0 (Código reciclado)
	return vidaActual
	
	
