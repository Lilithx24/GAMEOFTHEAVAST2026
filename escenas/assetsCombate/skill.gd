class_name Skill
extends Button

# @export para poder cambiar los campos desde el Inspector (A la derecha al seleccionar un nodo)
@export var nombreSkill: String = "nulo"
@export var dmgSkill: int
@export var staSkill: int
signal skillUsada(dmg: int, sta: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#text es el texto que aparece en el botón, es una variable predefinida por el tipo Button
	text = nombreSkill
	#Si no usas una funcion anónima(o funcion lambda, el func():) da error porque el connect espera un Callable (objeto llamable, ej: una función) de parámetro
	pressed.connect(func(): skillUsada.emit(dmgSkill, staSkill))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
