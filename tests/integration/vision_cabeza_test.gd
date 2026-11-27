extends SceneTree

var fallos := 0

func verificar(valor: bool, mensaje: String) -> void:
	if valor:
		print("OK: ", mensaje)
	else:
		fallos += 1
		push_error(mensaje)

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	var estado = root.get_node("EstadoPartida")
	var escena = load("res://escenas/Exploración/Pisos/PlantaCero.tscn").instantiate()
	root.add_child(escena)
	var vision = escena.get_node("VisionCabeza")
	verificar(not vision.efecto.visible and vision.copia.copy_mode == BackBufferCopy.COPY_MODE_DISABLED, "Sin cabeza no hay efecto ni copia adicional")
	verificar(vision.layer > escena.get_node("Shader").layer and vision.layer < escena.get_node("InteraccionObjetos").layer, "Visión después del retro y antes de botones")
	var menu = escena.get_node("MenuShift")
	verificar(vision.layer < menu.layer and vision.efecto.mouse_filter == Control.MOUSE_FILTER_IGNORE, "SHIFT queda encima y el efecto no intercepta clics")
	estado.recoger_parte("test_torso", load("res://Recursos/partes/torso_mantis.tres"))
	estado.recoger_parte("test_mosca", load("res://Recursos/partes/cabeza_mosca.tres"))
	estado.recoger_parte("test_humana", load("res://Recursos/partes/cabeza_humana.tres"))
	var mosca = estado.inventario[1]
	estado.equipar_parte("inventario", 0, "torso")
	estado.equipar_parte("inventario", estado.inventario.find(mosca), "cabeza")
	verificar(vision.efecto.visible and vision.efecto.material == estado.equipo.cabeza.vision_material, "Equipar mosca activa su material incluso siendo una copia de inventario")
	verificar(vision.copia.copy_mode == BackBufferCopy.COPY_MODE_VIEWPORT, "Se captura el resultado retro para el ojo compuesto")
	menu.abrir()
	verificar(vision.efecto.visible, "La visión continúa detrás de SHIFT")
	menu.cerrar()
	if "--capturar" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/vision_mosca.png")
		for i in range(10):
			await process_frame
		menu.abrir()
		for i in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		verificar(menu.visible, "SHIFT visible durante captura")
		root.get_texture().get_image().save_png("/tmp/vision_mosca_shift.png")
		menu.cerrar()
	estado.equipar_parte("inventario", 2, "cabeza")
	verificar(not vision.efecto.visible and vision.efecto.material == null, "Cambiar a humana restaura visión normal")
	estado.equipar_parte("inventario", estado.inventario.find(mosca), "cabeza")
	var nueva = load("res://escenas/Exploración/vision_cabeza.tscn").instantiate()
	root.add_child(nueva)
	verificar(nueva.efecto.visible, "Recrear controlador recupera la cabeza equipada")
	nueva.free()
	estado.desequipar_parte("cabeza")
	verificar(not vision.efecto.visible, "Quitar cabeza elimina efecto")
	estado.equipar_parte("inventario", estado.inventario.find(mosca), "cabeza")
	estado.desequipar_parte("torso")
	verificar(not vision.efecto.visible, "Quitar torso también retira visión al devolver cabeza")
	escena.queue_free()
	await process_frame
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
