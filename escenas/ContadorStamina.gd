extends HBoxContainer

var icono: Texture2D = preload("res://sprites/Indicador_Stamina.png")
@export var tamano_icono: Vector2 = Vector2(32, 32)

@onready var fila: HBoxContainer = $HBoxContainer/Rayos


func actualizar(actual: int) -> void:
	# Crea los iconos que falten
	while fila.get_child_count() < actual:
		var rayo := TextureRect.new()
		rayo.texture = icono
		rayo.custom_minimum_size = tamano_icono
		rayo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rayo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(rayo)

	# Muestra solo tantos como puntos de estamina haya
	for i in fila.get_child_count():
		fila.get_child(i).visible = i < actual

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
