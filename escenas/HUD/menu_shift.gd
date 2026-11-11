extends CanvasLayer

const CATEGORIAS: Array[String] = ["cabeza", "torso", "brazo", "piernas"]
const FILA_INVENTARIO := preload("res://escenas/HUD/fila_inventario.tscn")

@onready var inventario: VBoxContainer = %ListaInventario
@onready var pestanas: TabBar = %Pestañas
@onready var hoja: Control = %ZonaPersonaje
@onready var zona_inventario: Control = %ColumnaInventario
@onready var scroll: ScrollContainer = %ScrollInventario

var pausa_anterior: bool = false
var actualizacion_pendiente: bool = false
var filas_temporales: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var items_vacios: Array[ParteInventario] = []
	EstadoPartida.inicializar_inventario(items_vacios)
	for slot: Slot in inventario.get_children():
		_configurar_slot(slot)
	for slot: Slot in hoja.get_children():
		_configurar_slot(slot)
	hoja.set_drag_forwarding(Callable(), _puede_soltar_en_hoja, _soltar_en_hoja)
	for zona: Control in [zona_inventario, scroll, inventario]:
		zona.set_drag_forwarding(Callable(), _puede_devolver, _devolver)
	pestanas.tab_changed.connect(_on_pestana_cambiada)
	scroll.resized.connect(_ajustar_altura_filas)
	EstadoPartida.inventario_cambiado.connect(_solicitar_actualizacion)
	_actualizar_inventario()


func _configurar_slot(slot: Slot) -> void:
	slot.validar_entrega = _puede_entregar
	slot.entregar = _entregar


func _on_pestana_cambiada(_indice: int) -> void:
	scroll.scroll_vertical = 0
	_actualizar_inventario()


func _solicitar_actualizacion() -> void:
	# No eliminar una fila temporal mientras Godot procesa su drop.
	if not actualizacion_pendiente:
		actualizacion_pendiente = true
		_actualizar_inventario.call_deferred()


func _actualizar_inventario() -> void:
	actualizacion_pendiente = false
	for id in filas_temporales.keys():
		if not EstadoPartida.inventario_temporal.has(id):
			var fila: Slot = filas_temporales[id]
			inventario.remove_child(fila)
			fila.queue_free()
			filas_temporales.erase(id)
	for id in EstadoPartida.inventario_temporal:
		if not filas_temporales.has(id):
			var fila: Slot = FILA_INVENTARIO.instantiate()
			fila.name = "Temporal%d" % id
			fila.zona = "temporal"
			fila.indice = id
			inventario.add_child(fila)
			_configurar_slot(fila)
			filas_temporales[id] = fila

	var filtro: String = CATEGORIAS[pestanas.current_tab]
	for slot: Slot in inventario.get_children():
		var parte := EstadoPartida.parte_en(slot.zona, slot.indice)
		slot.poner_item(parte)
		slot.visible = parte != null and parte.tags.has(filtro)

	var capacidad := EstadoPartida.obtener_capacidad_brazos()
	for slot: Slot in hoja.get_children():
		slot.poner_item(EstadoPartida.parte_en(slot.zona, slot.indice))
		slot.visible = slot.zona != "brazo" or slot.indice < capacidad
	_ajustar_altura_filas()


func _ajustar_altura_filas() -> void:
	var separacion := inventario.get_theme_constant("separation")
	var alto := maxf(24.0, floorf((scroll.size.y - separacion * 3.0) / 4.0))
	for fila: Slot in inventario.get_children():
		fila.custom_minimum_size.y = alto


func _origen_valido(data: Variant) -> bool:
	return (
		data is Slot and is_instance_valid(data) and is_ancestor_of(data)
		and data.item != null and data.visible
		and data.item == EstadoPartida.parte_en(data.zona, data.indice)
	)


func _puede_entregar(origen: Slot, destino: Slot) -> bool:
	if not _origen_valido(origen) or origen == destino or not destino.visible:
		return false
	if destino.zona in ["inventario", "temporal"]:
		return _puede_devolver(Vector2.ZERO, origen)
	return EstadoPartida.puede_equipar(origen.zona, origen.indice, destino.zona, destino.indice)


func _entregar(origen: Slot, destino: Slot) -> void:
	if not _puede_entregar(origen, destino):
		return
	if destino.zona in ["inventario", "temporal"]:
		_devolver(Vector2.ZERO, origen)
	else:
		EstadoPartida.equipar_parte(origen.zona, origen.indice, destino.zona, destino.indice)


func _destino_en_hoja(data: Variant) -> Slot:
	if not _origen_valido(data) or data.zona not in ["inventario", "temporal"]:
		return null
	for slot: Slot in hoja.get_children():
		if _puede_entregar(data, slot):
			# Un brazo soltado sobre la hoja va al primer enganche libre.
			if slot.zona != "brazo" or slot.item == null:
				return slot
	return null


func _puede_soltar_en_hoja(_posicion: Vector2, data: Variant) -> bool:
	return _destino_en_hoja(data) != null


func _soltar_en_hoja(_posicion: Vector2, data: Variant) -> void:
	var destino := _destino_en_hoja(data)
	if destino != null:
		_entregar(data, destino)


func _puede_devolver(_posicion: Vector2, data: Variant) -> bool:
	return _origen_valido(data) and data.zona in ["cabeza", "torso", "piernas", "brazo"]


func _devolver(_posicion: Vector2, data: Variant) -> void:
	if _puede_devolver(_posicion, data):
		var categoria: String = data.zona
		EstadoPartida.desequipar_parte(data.zona, data.indice)
		pestanas.current_tab = CATEGORIAS.find(categoria)


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
	_actualizar_inventario()
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
