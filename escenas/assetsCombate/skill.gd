class_name Skill
extends PanelContainer

# @export para poder cambiar los campos desde el Inspector (A la derecha al seleccionar un nodo)
@export var nombreSkill: String = "None"
@export var dmgSkill: int
@export var staSkill: int
@export var efectos: Array[String] = []
@export var fondos: Array[Texture2D] = []

var _aspecto_elegido := false
var _arrastrando := false

var parte_origen: BrazoInventario

var disponible := true
var usada := false
var usosRestantes: int

@onready var etiquetaNombre: Label = $VBoxContainer/Nombre
@onready var etiquetaCoste: Label = $VBoxContainer/Coste


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not _aspecto_elegido and not fondos.is_empty():
		$Fondo.texture = fondos.pick_random()
		_aspecto_elegido = true
	# La carta conserva los datos del ataque de la pieza equipada.
	etiquetaNombre.text = nombreSkill
	etiquetaCoste.text = "%d STA" % staSkill
	$VBoxContainer/Damage.text = "%d damage" % dmgSkill
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
	$VBoxContainer/Estado.text = "Used" if usada else ("Drag onto an enemy" if disponible else "Not enough stamina")


# Godot llama a esta función cuando empiezas a arrastrar el nodo
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not disponible or usada:
		return null

	var copia: Control = duplicate()
	# La vista de arrastre conserva el PNG de la carta original.
	copia._aspecto_elegido = true
	copia.modulate.a = 0.8
	copia.position = -size / 2
	var preview := Control.new()
	preview.add_child(copia)
	set_drag_preview(preview)
	# Ocultar solo el dibujo mantiene el hueco y el orden de la mano.
	_arrastrando = true
	$Fondo.hide()
	$VBoxContainer.hide()

	return self

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _arrastrando:
		_arrastrando = false
		$Fondo.show()
		$VBoxContainer.show()
