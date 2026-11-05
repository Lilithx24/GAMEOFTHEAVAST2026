class_name Enemigo
extends Node2D
var vida: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vida = 100


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func sufrir_damage(damage: int):
	vida = vida - damage
	print("vida: ", vida)
