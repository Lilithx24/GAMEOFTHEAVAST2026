class_name PartePersonaje
extends Sprite2D

var skills: Array[Skill]
var tags: Array[String]
var estados: Array[String]
var datos: ParteInventario

func equipar(nuevos: ParteInventario) -> void:
	datos = nuevos
	texture = nuevos.textura if nuevos else null
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
