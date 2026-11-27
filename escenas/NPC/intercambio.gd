extends Control

@export var textos: TextosIntercambio = preload("res://Recursos/textos_intercambio.tres")
const ESTILO = preload("res://escenas/NPC/estilo_intercambio.gd")

var opcion := -1
var seleccion := -1
var fuentes: Array[Dictionary] = []
var botones: Array[Button] = []
var ocupado := false
var terminado := false
var lista: ItemList
var aceptar: Button
var salir: Button
var resumen: Label
var estado_texto: Label

@onready var contenido: VBoxContainer = $Margen/Panel/Contenido

func _ready() -> void:
	theme = ESTILO.crear_tema()
	$Margen/Panel.add_theme_stylebox_override("panel", ESTILO.papel())
	contenido.add_theme_font_size_override("font_size", 18)
	_label(textos.titulo, 26)
	estado_texto = _label(textos.instrucciones, 18)
	var ofertas = EstadoPartida.intercambio_npc.preparar(EstadoPartida)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	contenido.add_child(fila)
	for i in ofertas.size():
		var pieza: ParteInventario = ofertas[i]
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(0, 155)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.toggle_mode = true
		boton.theme_type_variation = "Oferta"
		boton.tooltip_text = pieza.nombre + "\n" + pieza.descripcion_habilidad
		fila.add_child(boton)
		var columna := VBoxContainer.new()
		columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		columna.offset_left = 6
		columna.offset_right = -6
		columna.offset_top = 8
		columna.offset_bottom = -8
		columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.add_child(columna)
		var categoria := Label.new()
		categoria.text = textos.categorias[i] if i < textos.categorias.size() else ""
		categoria.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		categoria.add_theme_font_size_override("font_size", 14)
		categoria.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna.add_child(categoria)
		var imagen := TextureRect.new()
		imagen.texture = pieza.textura
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.custom_minimum_size.y = 68
		imagen.size_flags_vertical = Control.SIZE_EXPAND_FILL
		imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna.add_child(imagen)
		var nombre := Label.new()
		nombre.text = pieza.nombre
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nombre.add_theme_font_size_override("font_size", 15)
		nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columna.add_child(nombre)
		boton.pressed.connect(_seleccionar_oferta.bind(i))
		botones.append(boton)
	_label(textos.titulo_inventario, 16)
	lista = ItemList.new()
	lista.custom_minimum_size.y = 120
	lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lista.fixed_icon_size = Vector2i(40, 40)
	lista.add_theme_font_size_override("font_size", 17)
	contenido.add_child(lista)
	_cargar_piezas()
	lista.item_selected.connect(_seleccionar_pieza)
	resumen = _label(textos.seleccion_pendiente, 16)
	resumen.custom_minimum_size.y = 46
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 16)
	contenido.add_child(acciones)
	aceptar = Button.new()
	aceptar.text = textos.aceptar
	aceptar.custom_minimum_size.y = 44
	aceptar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aceptar.disabled = true
	aceptar.pressed.connect(_aceptar)
	acciones.add_child(aceptar)
	salir = Button.new()
	salir.text = textos.cancelar
	salir.custom_minimum_size.y = 44
	salir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salir.pressed.connect(_salir)
	acciones.add_child(salir)
	if ofertas.is_empty():
		estado_texto.text = textos.espera if not EstadoPartida.intercambio_npc.disponible(EstadoPartida) else textos.sin_ofertas
	if fuentes.is_empty():
		resumen.text = textos.sin_piezas
	resized.connect(_colocar_npc)
	_colocar_npc()

func _label(texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	contenido.add_child(etiqueta)
	return etiqueta

func _colocar_npc() -> void:
	$NPC1.position = Vector2(size.x * 0.19, size.y * 0.9)
	$NPC1.scale = Vector2.ONE * minf(size.x * 0.37 / 842.0, size.y * 0.78 / 790.0)

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
		resumen.text = textos.resumen.format({"entregada": fuentes[seleccion].pieza.nombre, "recibida": EstadoPartida.intercambio_npc.ofertas[opcion].nombre})

func _aceptar() -> void:
	if ocupado or terminado or seleccion < 0 or opcion < 0:
		return
	var fuente := fuentes[seleccion]
	var recibida: ParteInventario = EstadoPartida.intercambio_npc.ofertas[opcion]
	if not EstadoPartida.intercambio_npc.entregar(EstadoPartida, fuente.zona, fuente.indice, fuente.pieza, opcion):
		resumen.text = textos.no_disponible
		aceptar.disabled = true
		return
	ocupado = true
	terminado = true
	aceptar.disabled = true
	salir.disabled = true
	lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for boton in botones:
		boton.disabled = true
	resumen.text = textos.trato_hecho.format({"recibida": recibida.nombre})
	estado_texto.text = textos.despedida
	await $NPC1.aceptar()
	ocupado = false
	salir.disabled = false
	salir.text = textos.salir
	salir.grab_focus()

func _salir() -> void:
	if ocupado:
		return
	var error := get_tree().change_scene_to_file(EstadoPartida.ESCENA_NIVEL)
	if error != OK:
		resumen.text = textos.error_salida

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_salir()
