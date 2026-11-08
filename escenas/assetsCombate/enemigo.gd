class_name Enemigo
extends Node2D
@onready var barra_vida: ProgressBar = $ProgressBar
var partes: Array[ParteEnemigo]

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
	objetivo.sufrirDmg(10)
