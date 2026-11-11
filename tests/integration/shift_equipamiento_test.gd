extends SceneTree
# Ejecutar con Godot --headless --path <proyecto> --script res://tests/integration/shift_equipamiento_test.gd

var fallos := 0
var estado: Node
var menu: CanvasLayer

func verificar(valor: bool, mensaje: String) -> void:
	if valor:
		print("OK: ", mensaje)
	else:
		fallos += 1
		push_error(mensaje)

func crear_parte(tipo: String, capacidad: int = 0) -> ParteInventario:
	var parte: ParteInventario = TorsoInventario.new() if tipo == "torso" else ParteInventario.new()
	parte.tags = [tipo]
	parte.nombre = tipo
	if parte is TorsoInventario:
		parte.slotsBrazos = capacidad
	return parte

func todas_las_piezas() -> Array:
	var piezas: Array = estado.inventario.filter(func(p): return p != null)
	piezas.append_array(estado.inventario_temporal.values())
	piezas.append_array(estado.equipo.values().filter(func(p): return p != null))
	piezas.append_array(estado.brazos_equipados.filter(func(p): return p != null))
	return piezas

func sin_duplicados() -> bool:
	var ids: Dictionary = {}
	for parte in todas_las_piezas():
		if ids.has(parte.get_instance_id()):
			return false
		ids[parte.get_instance_id()] = true
	return true

func fila(zona: String, indice: int) -> Slot:
	for slot: Slot in menu.inventario.get_children():
		if slot.zona == zona and slot.indice == indice:
			return slot
	return null

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	root.size = Vector2i(1152, 648)
	estado = root.get_node("EstadoPartida")
	menu = load("res://escenas/HUD/menu_shift.tscn").instantiate()
	root.add_child(menu)
	menu.abrir()
	var vacios: Array[ParteInventario] = []
	estado.inicializar_inventario(vacios)
	for n in [2, 4, 6, 8]:
		estado.recoger_parte("torso%d" % n, crear_parte("torso", n))
	for i in 8:
		estado.recoger_parte("brazo%d" % i, crear_parte("brazo"))
	estado.recoger_parte("cabeza", crear_parte("cabeza"))
	estado.recoger_parte("piernas", crear_parte("piernas"))
	menu.pestanas.current_tab = 2
	await process_frame
	await process_frame
	var cantidad := todas_las_piezas().size()
	var brazo: Slot = fila("inventario", 4)
	verificar(not menu._puede_soltar_en_hoja(Vector2.ZERO, brazo), "No se equipan brazos sin torso")
	verificar(menu.hoja.get_children().size() == 11, "Cabeza, torso, piernas y ocho enganches existen en el editor")
	var alto: float = menu.scroll.size.y
	verificar(is_equal_approx(brazo.custom_minimum_size.y * 4 + 24, floorf(alto / 4) * 4) or absf(brazo.custom_minimum_size.y * 4 + 24 - alto) < 4, "La lista reserva altura para cuatro filas")

	menu.pestanas.current_tab = 1
	menu._soltar_en_hoja(Vector2.ZERO, fila("inventario", 3))
	await process_frame
	verificar(estado.obtener_capacidad_brazos() == 8, "Soltar el torso en la hoja lo equipa")
	verificar(estado.inventario[3] == null, "La pieza equipada sale del inventario")
	verificar(menu.hoja.get_children().filter(func(s): return s.zona == "brazo" and s.visible).size() == 8, "Torso de ocho muestra ocho enganches")

	menu.pestanas.current_tab = 2
	for i in 8:
		menu._soltar_en_hoja(Vector2.ZERO, fila("inventario", 4 + i))
		await process_frame
	verificar(estado.brazos_equipados.filter(func(p): return p != null).size() == 8, "Cada brazo ocupa un enganche distinto")
	verificar(menu.inventario.get_children().filter(func(s): return s.visible).is_empty(), "Los brazos equipados no figuran en su pestaña")
	var primero: ParteInventario = estado.brazos_equipados[0]
	var ultimo: ParteInventario = estado.brazos_equipados[7]
	var slot1: Slot = menu.hoja.get_node("Brazo1")
	var slot8: Slot = menu.hoja.get_node("Brazo8")
	verificar(slot8._can_drop_data(Vector2.ZERO, slot1), "Los brazos admiten intercambio entre enganches")
	slot8._drop_data(Vector2.ZERO, slot1)
	await process_frame
	verificar(estado.brazos_equipados[0] == ultimo and estado.brazos_equipados[7] == primero, "Intercambio conserva ambos brazos")
	verificar(not menu.hoja.get_node("Cabeza")._can_drop_data(Vector2.ZERO, slot1), "Se rechaza un brazo en la cabeza")

	for dato in [[0, "cabeza", 12], [3, "piernas", 13]]:
		menu.pestanas.current_tab = dato[0]
		menu._soltar_en_hoja(Vector2.ZERO, fila("inventario", dato[2]))
		await process_frame
		verificar(estado.equipo[dato[1]] != null, "Se equipa " + dato[1])

	menu.pestanas.current_tab = 1
	for dato in [[2, 6], [1, 4], [0, 2]]:
		menu._soltar_en_hoja(Vector2.ZERO, fila("inventario", dato[0]))
		await process_frame
		verificar(estado.obtener_capacidad_brazos() == dato[1], "Cambio de torso reduce capacidad a %d" % dato[1])
		verificar(estado.brazos_equipados.filter(func(p): return p != null).size() == dato[1], "Solo quedan los brazos admitidos")
		verificar(todas_las_piezas().size() == cantidad and sin_duplicados(), "Cambio conserva cada pieza exactamente una vez")

	# Llenar los 20 huecos normales y devolver un cuerpo entero.
	var n := 0
	while estado.inventario.has(null):
		estado.recoger_parte("relleno%d" % n, crear_parte("cabeza"))
		n += 1
	await process_frame
	cantidad = todas_las_piezas().size()
	menu._devolver(Vector2.ZERO, menu.hoja.get_node("Torso"))
	await process_frame
	verificar(estado.equipo.values().all(func(p): return p == null), "Quitar torso devuelve torso, cabeza y piernas")
	verificar(estado.brazos_equipados.all(func(p): return p == null), "Quitar torso devuelve todos los brazos")
	verificar(estado.inventario_temporal.size() == 5, "Sin espacio se crean cinco huecos temporales")
	verificar(menu.filas_temporales.size() == 5, "La vista representa todos los huecos temporales")
	verificar(todas_las_piezas().size() == cantidad and sin_duplicados(), "Desmontaje no pierde ni duplica piezas")
	verificar(estado.recoger_parte("sin_espacio", crear_parte("brazo")) == "lleno", "Los temporales no aumentan la capacidad de recogida normal")

	var id_torso: int = -1
	var id_brazo: int = -1
	for id in estado.inventario_temporal:
		if estado.inventario_temporal[id].tags.has("torso"):
			id_torso = id
		if estado.inventario_temporal[id].tags.has("brazo"):
			id_brazo = id
	menu.pestanas.current_tab = 1
	menu._soltar_en_hoja(Vector2.ZERO, fila("temporal", id_torso))
	await process_frame
	verificar(not estado.inventario_temporal.has(id_torso) and not menu.filas_temporales.has(id_torso), "Al sacar un torso temporal desaparece su hueco")
	menu.pestanas.current_tab = 2
	menu._soltar_en_hoja(Vector2.ZERO, fila("temporal", id_brazo))
	await process_frame
	verificar(not estado.inventario_temporal.has(id_brazo) and not menu.filas_temporales.has(id_brazo), "Al sacar un brazo temporal desaparece su hueco")
	verificar(todas_las_piezas().size() == cantidad and sin_duplicados(), "Reequipar temporales mantiene todas las piezas")

	menu.cerrar()
	menu.queue_free()
	await process_frame
	menu = load("res://escenas/HUD/menu_shift.tscn").instantiate()
	root.add_child(menu)
	menu.abrir()
	verificar(menu.filas_temporales.size() == estado.inventario_temporal.size(), "Los temporales persisten al recrear el menú")
	verificar(menu.hoja.get_node("Torso").item == estado.equipo["torso"], "El equipo persiste al recrear el menú")
	verificar(todas_las_piezas().size() == cantidad and sin_duplicados(), "Reabrir no duplica ninguna pieza")
	menu.cerrar()
	menu.queue_free()
	await process_frame
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
