class_name Enemigo
extends Node2D
@onready var barra_vida: ProgressBar = $ProgressBar
var partes: Array[ParteEnemigo]
var dmg: int = 10
@export var stun: int = 0
@export var debilContador: int = 0
@export var debilEstado: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func actualizar_barra() -> void:
	var vida_max_total := 0
	var vida_actual_total := 0
	for parte in partes:
		vida_max_total += parte.vidaMax
		vida_actual_total += parte.vidaActual
	barra_vida.max_value = vida_max_total
	barra_vida.value = vida_actual_total

func turno(objetivo: Personaje) -> void:
	#checkea si el enemigo está débil y actualiza los valores
	if debilContador > 0:
		debilEstado = 1
		debilContador = debilContador - 1
	else:
		debilEstado = 0
	
	if stun == 0:
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	else:
		stun = stun - 1 
