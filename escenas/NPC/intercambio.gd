extends Node2D

# Mensajes variables editables en el nodo raíz de Intercambio.
@export_multiline var mensaje_espera: String = ""
@export_multiline var mensaje_sin_ofertas: String = ""
@export_multiline var mensaje_sin_piezas: String = ""
@export_multiline var mensaje_resumen: String = ""
@export_multiline var mensaje_no_disponible: String = ""
@export_multiline var mensaje_trato_hecho: String = ""
@export_multiline var mensaje_despedida: String = ""
@export_multiline var mensaje_error_salida: String = ""

var opcion := -1
var seleccion := -1
var fuentes: Array[Dictionary] = []
var botones: Array[Button] = []
var ocupado := false
var terminado := false

@onready var lista: ItemList = %Inventario
@onready var aceptar: Button = %Aceptar
@onready var salir: Button = %Salir
@onready var resumen: Label = %Resumen
@onready var estado_texto: Label = %Estado

func _ready() -> void:
	# El diseño, los tamaños y el tema se editan en Intercambio.tscn.
	# Solo las ofertas y el inventario dependen de la partida.
	botones.assign([%Torso, %Brazo, %Cabeza, %Piernas])
	var ofertas = EstadoPartida.intercambio_npc.preparar(EstadoPartida)
	for i in botones.size():
		var boton := botones[i]
		boton.visible = i < ofertas.size()
		if i >= ofertas.size():
			continue
		var pieza: ParteInventario = ofertas[i]
		boton.tooltip_text = pieza.nombre + "\n" + pieza.descripcion_habilidad
		boton.get_node("Contenido/Imagen").texture = pieza.textura
		boton.get_node("Contenido/Nombre").text = pieza.nombre
		boton.pressed.connect(_seleccionar_oferta.bind(i))
	_cargar_piezas()
	lista.item_selected.connect(_seleccionar_pieza)
	aceptar.pressed.connect(_aceptar)
	salir.pressed.connect(_salir)
	if ofertas.is_empty():
		estado_texto.text = mensaje_espera if not EstadoPartida.intercambio_npc.disponible(EstadoPartida) else mensaje_sin_ofertas
	if fuentes.is_empty():
		resumen.text = mensaje_sin_piezas

func _cargar_piezas() -> void:
	for i in EstadoPartida.inventario.size():
		_agregar_pieza("inventario", i, EstadoPartida.inventario[i])
	for i in EstadoPartida.inventario_temporal:
		_agregar_pieza("temporal", i, EstadoPartida.inventario_temporal[i])

func _agregar_pieza(zona: String, indice: int, pieza: ParteInventario) -> void:
	if pieza == null:
		return
	fuentes.append({"zona": zona, "indice": indice, "pieza": pieza})
	lista.add_item(pieza.nombre, pieza.textura)

func _seleccionar_oferta(indice: int) -> void:
	if ocupado or terminado:
		return
	opcion = indice
	for i in botones.size():
		botones[i].set_pressed_no_signal(i == opcion)
	_actualizar_resumen()

func _seleccionar_pieza(indice: int) -> void:
	seleccion = indice
	_actualizar_resumen()

func _actualizar_resumen() -> void:
	aceptar.disabled = terminado or ocupado or opcion < 0 or seleccion < 0
	if not aceptar.disabled:
		resumen.text = mensaje_resumen.format({"entregada": fuentes[seleccion].pieza.nombre, "recibida": EstadoPartida.intercambio_npc.ofertas[opcion].nombre})

func _aceptar() -> void:
	if ocupado or terminado or seleccion < 0 or opcion < 0:
		return
	var fuente := fuentes[seleccion]
	var recibida: ParteInventario = EstadoPartida.intercambio_npc.ofertas[opcion]
	if not EstadoPartida.intercambio_npc.entregar(EstadoPartida, fuente.zona, fuente.indice, fuente.pieza, opcion):
		resumen.text = mensaje_no_disponible
		aceptar.disabled = true
		return
	ocupado = true
	terminado = true
	aceptar.disabled = true
	salir.disabled = true
	lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for boton in botones:
		boton.disabled = true
	resumen.text = mensaje_trato_hecho.format({"recibida": recibida.nombre})
	estado_texto.text = mensaje_despedida
	await $NPC1.aceptar()
	ocupado = false
	salir.disabled = false
	salir.grab_focus()

func _salir() -> void:
	if ocupado:
		return
	var error := get_tree().change_scene_to_file(EstadoPartida.ESCENA_NIVEL)
	if error != OK:
		resumen.text = mensaje_error_salida

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_salir()
