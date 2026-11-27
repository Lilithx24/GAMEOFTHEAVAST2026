extends SceneTree

var fallos := 0

func verificar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)
	else:
		print("OK: ", mensaje)

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	seed(12345)
	var estado = root.get_node("EstadoPartida")
	var escena = load("res://escenas/Exploración/Piezas/CajaPlastico.tscn")
	var ids := {}
	for tipo in range(4):
		var caja = escena.instantiate()
		caja.tipo_parte = tipo
		caja.name = "Caja%d" % tipo
		root.add_child(caja)
		verificar(not ids.has(caja.id_objeto), "ID automático independiente al duplicar cajas")
		ids[caja.id_objeto] = true
		var pool = caja.POOLS[tipo]
		verificar(not pool.partes.is_empty() and pool.candidatas().size() == pool.partes.size(), "Pool completo y sin piezas de otro tipo")
		var vistas := {}
		var categoria_correcta := true
		for i in range(200):
			var parte = pool.sortear()
			categoria_correcta = categoria_correcta and parte != null and parte.tags.has(pool.tipo)
			vistas[parte] = true
		verificar(categoria_correcta, "200 sorteos respetan categoría")
		verificar(vistas.size() > 1, "El pool ofrece variedad")
		var premio = caja.obtener_recompensa()
		verificar(caja.obtener_recompensa() == premio, "Reintentar conserva premio")
		var id: String = caja.id_objeto
		caja.free()
		caja = escena.instantiate()
		caja.id_objeto = id
		caja.tipo_parte = tipo
		caja.name = "Caja%d" % tipo
		root.add_child(caja)
		verificar(caja.obtener_recompensa() == premio, "Recargar conserva premio pendiente")
		verificar(estado.recoger_parte(id, premio) == "ok", "Recoge premio")
		verificar(not caja.disponible(), "Caja consumida queda desactivada")
		verificar(estado.recoger_parte(id, premio) == "recogido", "No duplica recompensa de una caja")
		verificar(estado.recoger_parte(id + "_otra", premio) == "ok", "Otra caja puede dar la misma pieza")
		var ocupadas = estado.inventario.filter(func(p): return p != null)
		verificar(ocupadas[-1] != ocupadas[-2] and ocupadas[-1].nombre == ocupadas[-2].nombre, "Duplicados son ejemplares independientes")
		caja.free()
		caja = escena.instantiate()
		caja.id_objeto = id
		root.add_child(caja)
		verificar(not caja.disponible(), "Recargar no repone una caja recogida")
		caja.free()
	var llena = escena.instantiate()
	root.add_child(llena)
	var premio = llena.obtener_recompensa()
	for i in range(estado.inventario.size()):
		estado.inventario[i] = premio.duplicate(true)
	verificar(estado.recoger_parte(llena.id_objeto, premio) == "lleno" and llena.disponible(), "SHIFT lleno no consume caja")
	estado.inventario[0] = null
	verificar(estado.recoger_parte(llena.id_objeto, llena.obtener_recompensa()) == "ok", "Recoge tras liberar espacio")
	llena.free()
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
