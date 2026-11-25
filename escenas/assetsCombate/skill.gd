class_name Skill
extends PanelContainer

# @export para poder cambiar los campos desde el Inspector (A la derecha al seleccionar un nodo)
@export var nombreSkill: String = "nulo"
@export var dmgSkill: int
@export var staSkill: int
@export var efectos: Array[String] = []

var parte_origen: BrazoInventario

var disponible := true
var usada := false
var usosRestantes: int

@onready var etiquetaNombre: Label = $VBoxContainer/Nombre
@onready var etiquetaCoste: Label = $VBoxContainer/Coste


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# La carta conserva los datos del ataque de la pieza equipada.
	etiquetaNombre.text = nombreSkill
	etiquetaCoste.text = "%d STA" % staSkill
	$VBoxContainer/Damage.text = "%d de daño" % dmgSkill
	if parte_origen:
		$VBoxContainer/Imagen.texture = parte_origen.textura
		$VBoxContainer/Origen.text = parte_origen.nombre
		tooltip_text = parte_origen.descripcion_habilidad
	_actualizar_estado()


func updateDisponibilidad(stamina_actual: int) -> void:
	disponible = staSkill <= stamina_actual
	_actualizar_estado()

func marcarUsada() -> void:
	usada = true
	if parte_origen != null:
		parte_origen.gastar_uso()
	_actualizar_estado()

func recuperar() -> void:
	usada = false
	_actualizar_estado()

func _actualizar_estado() -> void:
	modulate = Color.WHITE if disponible and not usada else Color(0.55, 0.55, 0.55)
	$VBoxContainer/Estado.text = "Usada" if usada else ("Arrastra al enemigo" if disponible else "Sin stamina")


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
