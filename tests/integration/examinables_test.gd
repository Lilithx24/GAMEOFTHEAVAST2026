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
	var escena = load("res://escenas/Exploración/Pisos/PlantaCero.tscn").instantiate()
	root.add_child(escena)
	var ui = escena.get_node("InteraccionObjetos")
	ui.set_physics_process(false)
	var primera = escena.get_node("PisoCero/ObjetosExaminables/CajaInicio")
	var segunda = escena.get_node("PisoCero/ObjetosExaminables/CajaInicio2")
	await physics_frame
	await physics_frame
	verificar(primera.get_node("CollisionShape3D").shape != segunda.get_node("CollisionShape3D").shape, "Cada caja tiene una forma independiente")
	verificar(primera.id_objeto != segunda.id_objeto, "Las cajas tienen identificadores distintos")
	for caja in [primera, segunda]:
		ui.camara.look_at(caja.punto_interaccion())
		verificar(ui._es_accesible(caja), "%s accesible con colisión desplazada" % caja.name)
		verificar(ui._lanzar_rayo(ui.camara.global_position, caja.punto_interaccion()).get("collider") == caja, "%s detectada por su colisión" % caja.name)
	ui.camara.look_at(primera.punto_interaccion())
	ui.objetivo = primera
	ui.boton.pressed.emit()
	ui._physics_process(0.016)
	verificar(not primera.disponible(), "La primera caja se recoge con el botón")
	verificar(segunda.disponible(), "Recoger la primera no consume la segunda")
	ui.camara.look_at(segunda.punto_interaccion())
	verificar(ui._es_accesible(segunda), "La segunda sigue siendo accesible")
	ui.objetivo = segunda
	ui.boton.pressed.emit()
	ui._physics_process(0.016)
	verificar(not segunda.disponible(), "La segunda caja también se recoge")
	verificar(root.get_node("EstadoPartida").inventario.filter(func(p): return p != null).size() == 2, "Se conservan ambas recompensas")
	escena.queue_free()
	await process_frame
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
