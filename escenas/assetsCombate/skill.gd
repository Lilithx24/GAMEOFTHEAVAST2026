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
	etiquetaNombre.text = parte_origen.nombre if parte_origen != null else nombreSkill
	etiquetaCoste.text = str(staSkill)
	$VBoxContainer/Damage.text = "%d damage" % dmgSkill
	if parte_origen:
		$VBoxContainer/Imagen.texture = parte_origen.textura
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
	$VBoxContainer/Estado.text = "Used" if usada else ("" if disponible else "Not enough stamina")


# Godot llama a esta función cuando empiezas a arrastrar el nodo
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not disponible or usada:
		return null

	var copia: Control = duplicate()
	# La vista de arrastre conserva el PNG de la carta original.
	copia._aspecto_elegido = true
	copia.parte_origen = parte_origen
	copia.rotation = 0.0
	copia.z_index = 0
	copia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copia.modulate.a = 0.8
	copia.position = -size / 2
	var preview := Control.new()
	preview.name = "VistaArrastreCarta"
	# Godot separa la vista de arrastre de la mano: no hereda su orden Z.
	preview.z_as_relative = false
	preview.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
