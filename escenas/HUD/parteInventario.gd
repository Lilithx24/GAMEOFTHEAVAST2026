class_name ParteInventario
extends Resource

@export var nombre: String
@export_multiline var descripcion_habilidad: String = ""
@export var textura: Texture2D
#@export var skills: Array[Skill]
@export var tags: Array[String]
@export var estados: Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
