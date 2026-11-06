class_name Personaje
extends Node

var vidaMax: int = 100
var vidaActual: int
@onready var barra_vida: ProgressBar = $ProgressBarJ


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func actualizar_barra() -> void:
#	barra_vida.max_value = vidaMax
#	barra_vida.value = vidaActual

#func sufrirDmg(damage: int):
#	vidaActual = vidaActual - damage

	
	
