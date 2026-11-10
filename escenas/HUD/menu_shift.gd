extends CanvasLayer

const ESCENA_SLOT := preload("res://escenas/HUD/slot.tscn")

@export var items_iniciales: Array[ParteInventario]
@export var parte_brazo: PartePersonaje
@export var parte_torso: PartePersonaje
@export var parte_piernas: PartePersonaje

@onready var inventario: GridContainer = %GridContainer
@onready var destino: GridContainer = %GridContainer2

var pausa_anterior: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # necesario: el juego está en pausa con el menú abierto
	hide()                                    # el menú empieza cerrado
	inventario.columns = 4
	destino.columns = 2

	for i in 20:
		_crear_slot(inventario)
		
	var slot_torso := _crear_slot(destino)
	slot_torso.tag_requerido = "torso"
	slot_torso.item_cambiado.connect(_on_parte_equipada.bind(parte_torso))
	
	var slot_piernas := _crear_slot(destino)
	slot_piernas.tag_requerido = "piernas"
	slot_piernas.item_cambiado.connect(_on_parte_equipada.bind(parte_piernas))
	

	for i in 4:
		var slot_brazo := _crear_slot(destino)
		slot_brazo.tag_requerido = "brazo"
		slot_brazo.item_cambiado.connect(_on_parte_equipada.bind(parte_brazo))
	
	for i in items_iniciales.size():
		(inventario.get_child(i) as Slot).poner_item(items_iniciales[i])

func _crear_slot(grid: GridContainer) -> Slot:
	var slot: Slot = ESCENA_SLOT.instantiate()
	grid.add_child(slot)
	return slot


func _on_parte_equipada(slot: Slot, parte: PartePersonaje) -> void:
	if parte:
		parte.equipar(slot.item)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_shift"):
		abrir()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("menu_shift"):
		cerrar()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	if visible:
		return
	pausa_anterior = get_tree().paused
	show()
	get_tree().paused = true


func cerrar() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = pausa_anterior


func _notification(what: int) -> void:
	# Evita dejar el menú abierto si se suelta Shift fuera de la ventana.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		cerrar()


func _exit_tree() -> void:
	if visible:
		get_tree().paused = pausa_anterior
