class_name Enemigo
extends Node2D
@onready var barra_vida: ProgressBar = $ProgressBar
var parte: ParteEnemigo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func actualizar_barra() -> void:
	barra_vida.max_value = parte.vidaMax
	barra_vida.value = parte.vidaActual
