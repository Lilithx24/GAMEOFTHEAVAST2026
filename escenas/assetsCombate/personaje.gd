class_name Personaje
extends Node

signal murio
signal esquivo
signal vida_cambiada

###### stats ######
var vidaMax: int = 50
var staminaBase: int = 2
var stamina: int = 2
var evasion: int = 0
var proteccion: float = 0.0
var modDmg: int = 0

var vidaActual: int
var partes: Array[PartePersonaje]
var estados: Array[PartePersonaje]
var stun: int = 0
var debilContador: int = 0
var debilEstado: int = 0
@onready var barra_vida: ProgressBar = $ProgressBarJ
var staminaActual: int

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func actualizar_barra() -> void:
	barra_vida.max_value = vidaMax
	barra_vida.value = vidaActual


func sufrirDmg(damage: int):
	var probImpacto: int = (100 - evasion)
	var tiradaAtaque: int = randi() % 100
	if tiradaAtaque < probImpacto:
		var reduccion: float = proteccion / 100.0          
		var danoFinal: float = damage * (1.0 - reduccion)  
		setVidaActual(vidaActual - danoFinal)
	else:
		esquivo.emit()
	if vidaActual <= 0:
		murio.emit()

func setVidaActual(vida: int) -> int:
	vidaActual = clampi(vida, 0, vidaMax) #Esta mierda es pa que no baje de 0 (Código reciclado)
	vida_cambiada.emit()
	return vidaActual
	
	
