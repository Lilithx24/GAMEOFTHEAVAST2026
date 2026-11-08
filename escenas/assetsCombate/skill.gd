class_name Skill
extends PanelContainer

# @export para poder cambiar los campos desde el Inspector (A la derecha al seleccionar un nodo)
@export var nombreSkill: String = "nulo"
@export var dmgSkill: int
@export var staSkill: int

var disponible := true
var usada := false

@onready var etiquetaNombre: Label = $VBoxContainer/Nombre
@onready var etiquetaCoste: Label = $VBoxContainer/Coste


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ya no hay "text" como en Button: el texto va en los Label hijos
	etiquetaNombre.text = nombreSkill
	etiquetaCoste.text = "%d STA" % staSkill

func updateDisponibilidad(stamina_actual: int) -> void:
	disponible = staSkill <= stamina_actual
	if usada:
		return
	modulate = Color.WHITE if disponible else Color(0.5, 0.5, 0.5)

func marcarUsada() -> void:
	usada = true
	modulate = Color(0.4, 0.4, 0.4)

func recuperar() -> void:
	usada = false
	modulate = Color.WHITE

# Godot llama a esta función cuando empiezas a arrastrar el nodo
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not disponible or usada:
		return null

	var copia: Control = duplicate()
	copia.modulate.a = 0.8
	copia.position = -size / 2
	var preview := Control.new()
	preview.add_child(copia)
	set_drag_preview(preview)

	return self

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
