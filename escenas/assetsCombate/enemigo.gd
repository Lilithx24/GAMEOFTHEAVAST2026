class_name Enemigo
extends Node2D
@export var vidaActual: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func sufrirDmg(damage: int):
	var nuevaVida = setVidaActual(vidaActual - damage)
	print("vida restante: ", nuevaVida)

func setVidaActual(vida: int) -> int:
	vidaActual = vida
	return vidaActual
