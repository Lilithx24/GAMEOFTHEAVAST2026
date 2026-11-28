extends SceneTree

var fallos := 0
var estado: Node

func verificar(valor: bool, mensaje: String) -> void:
	if valor:
		print("OK: ", mensaje)
	else:
		fallos += 1
		push_error(mensaje)

func _initialize() -> void:
	call_deferred("probar")

func captura(nombre: String) -> void:
	if "--capturar" not in OS.get_cmdline_user_args():
		return
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/npc_" + nombre + ".png")

func probar() -> void:
	estado = root.get_node("EstadoPartida")
	var editable = load("res://escenas/NPC/Intercambio.tscn").instantiate()
	verificar(editable is Node2D, "Intercambio es una escena 2D")
	var titulo = editable.get_node("Interfaz/Margen/Panel/Contenido/Titulo")
	verificar(not titulo.get_parent() is Container, "El diseño permite recolocar elementos sin un Container")
	titulo.position += Vector2(12, 6)
	titulo.text = "Título editado desde la escena"
	var posicion_titulo: Vector2 = titulo.position
	editable.get_node("NPC1").position += Vector2(20, -10)
	var posicion_editada: Vector2 = editable.get_node("NPC1").position
	root.add_child(editable)
	await process_frame
	verificar(titulo.position.is_equal_approx(posicion_titulo) and titulo.text == "Título editado desde la escena", "Arrancar conserva la posición y el texto editados")
	verificar(editable.get_node("NPC1").position.is_equal_approx(posicion_editada), "Arrancar conserva la posición editada del NPC")
	verificar(editable.botones.size() == 4 and editable.botones.all(func(b): return b.owner == editable), "Las cuatro ofertas existen como nodos guardados en la escena")
	editable.queue_free()
	await process_frame
	estado.intercambio_npc.reiniciar()
	var nivel = load(estado.ESCENA_NIVEL).instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await physics_frame
	await physics_frame
	var npc = nivel.get_node("NPCIntercambio")
	var posicion_npc: Transform3D = npc.global_transform
	var jugador = nivel.get_node("PisoCero/Jugador")
	jugador.global_position = npc.global_position + Vector3(-3, 1.32, 0)
	jugador.look_at(Vector3(npc.global_position.x, jugador.global_position.y, npc.global_position.z))
	var posicion_jugador: Transform3D = jugador.global_transform
	var ui = nivel.get_node("InteraccionObjetos")
	ui.set_physics_process(false)
	var impacto = ui._lanzar_rayo(ui.camara.global_position, npc.punto_interaccion())
	verificar(impacto.get("collider") == npc.get_node("Cuerpo"), "NPC accesible desde una posición cercana")
	ui._mostrar_interaccion(impacto)
	verificar(ui.boton_interactuar.visible, "NPC muestra INTERACTUAR")
	verificar(not npc.is_in_group("enemigos_exploracion") and not root.get_node("TransicionCombate").en_curso, "NPC no inicia combate ni embestida")
	await captura("mapa")
	ui._mostrar_interaccion(impacto)
	ui.boton_interactuar.pressed.emit()
	ui._physics_process(0.016)
	await scene_changed
	var intercambio = current_scene
	verificar(intercambio.fuentes.is_empty() and intercambio.aceptar.disabled, "Sin piezas se puede salir pero no aceptar")
	var ofertas: Array = estado.intercambio_npc.ofertas.duplicate()
	verificar(ofertas.size() == 4, "Ofrece cuatro piezas")
	for i in 4:
		verificar(ofertas[i].tags.has(["torso", "brazo", "cabeza", "piernas"][i]), "Una oferta de cada pool")
	intercambio._salir()
	await scene_changed
	nivel = current_scene
	verificar(nivel.get_node("PisoCero/Jugador").global_transform.is_equal_approx(posicion_jugador), "Cancelar devuelve al mismo punto y orientación")
	verificar(estado.intercambio_npc.disponible(estado) and estado.intercambio_npc.ofertas == ofertas, "Cancelar conserva ofertas y disponibilidad")
	estado.recoger_parte("torso_test", load("res://Recursos/partes/torso_mantis.tres"))
	estado.equipar_parte("inventario", 0, "torso")
	verificar(not estado.intercambio_npc.entregar(estado, "torso", 0, estado.equipo.torso, 0), "Se rechaza entregar piezas equipadas")
	for i in 20:
		estado.recoger_parte("pieza_%d" % i, load("res://Recursos/partes/brazo_cangrejo.tres"))
	estado.enemigos_derrotados["previo"] = true
	nivel.get_node("NPCIntercambio").interactuar()
	await scene_changed
	intercambio = current_scene
	verificar(intercambio.fuentes.size() == 20, "Solo muestra las piezas sin equipar")
	intercambio._seleccionar_oferta(2)
	intercambio._seleccionar_pieza(0)
	await captura("ofertas")
	var recibida: ParteInventario = ofertas[2]
	await intercambio._aceptar()
	verificar(estado.inventario[0].nombre == recibida.nombre and estado.inventario[0] != recibida, "Entrega una copia independiente con SHIFT lleno")
	verificar(estado.equipo.torso != null and estado.inventario.filter(func(p): return p != null).size() == 20, "Trato conserva el equipo y el número de piezas")
	verificar(not estado.intercambio_npc.disponible(estado), "Victorias anteriores no desbloquean otro trato")
	verificar(not estado.intercambio_npc.entregar(estado, "inventario", 0, estado.inventario[0], 0), "No permite confirmar dos veces")
	verificar(intercambio.get_node("NPC1/AnimationPlayer").current_animation == "idle", "Gesto de aceptación vuelve a idle")
	await captura("aceptado")
	intercambio._salir()
	await scene_changed
	nivel = current_scene
	npc = nivel.get_node("NPCIntercambio")
	verificar(npc.global_transform.is_equal_approx(posicion_npc), "NPC permanece en su sitio")
	var dialogo_esperado: String = npc.get_node("Dialogo").dialog_text
	npc.interactuar()
	verificar(npc.get_node("Dialogo").visible and npc.get_node("Dialogo").dialog_text == dialogo_esperado and not dialogo_esperado.is_empty(), "Sin nueva victoria muestra el diálogo solicitado")
	await captura("dialogo")
	npc.get_node("Dialogo").hide()
	npc._cerrar_dialogo()
	verificar(not paused, "Cerrar diálogo devuelve el control")
	estado.enemigos_derrotados["previo"] = true
	verificar(not estado.intercambio_npc.disponible(estado), "Repetir el mismo enemigo no desbloquea")
	estado.enemigos_derrotados["nuevo"] = true
	verificar(estado.intercambio_npc.disponible(estado) and estado.intercambio_npc.preparar(estado).size() == 4, "Una nueva victoria habilita cuatro ofertas")
	var falsa := ParteInventario.new()
	verificar(not estado.intercambio_npc.entregar(estado, "inventario", 0, falsa, 0), "Rechaza selección que ya no coincide con el inventario")
	estado.inventario_temporal[7] = falsa
	verificar(estado.intercambio_npc.entregar(estado, "temporal", 7, falsa, 0), "Admite piezas sin equipar de huecos temporales")
	estado.intercambio_npc.reiniciar()
	verificar(estado.intercambio_npc.disponible(estado) and estado.intercambio_npc.ofertas.is_empty(), "Nueva partida reinicia el trato")
	current_scene = null
	nivel.queue_free()
	await process_frame
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
