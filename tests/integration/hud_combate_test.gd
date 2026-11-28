extends SceneTree
var errors := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		errors += 1
		push_error(label)
	else:
		print("OK: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1152, 648)
	var state = root.get_node("EstadoPartida")
	var paths = ["brazo_humano", "brazo_ak47", "brazo_cerveza", "brazo_mantis", "brazo_cangrejo", "brazo_gancho_mecanico"]
	for path in paths:
		var part = load("res://Recursos/partes/" + path + ".tres").duplicate()
		part.staSkill = 1
		state.brazos_equipados.append(part)
	var combat = load("res://escenas/Combate.tscn").instantiate()
	root.add_child(combat)
	for i in 4:
		await process_frame
	check(not combat.aviso_turno.visible, "Hay cartas jugables: sin aviso")
	var hand = combat.contenedor
	check(hand.get_child_count() == 6, "Seis cartas en la mano")
	check(hand.get_child(0).rotation < 0 and hand.get_child(5).rotation > 0, "Abanico simétrico")
	check(hand.get_child(0).position.y > hand.get_child(2).position.y, "Las cartas siguen un arco")
	var first = hand.get_child(0)
	var movement := InputEventMouseMotion.new()
	movement.position = first.get_global_transform() * Vector2(30, 70)
	root.push_input(movement)
	check(hand.enfocada == first and is_zero_approx(first.rotation), "Apuntar eleva y endereza la carta")
	check(first.mouse_filter == Control.MOUSE_FILTER_STOP and hand.get_child(1).mouse_filter == Control.MOUSE_FILTER_IGNORE, "El solapamiento no intercepta el arrastre de la carta enfocada")
	movement.position = Vector2(0, 0)
	root.push_input(movement)
	check(not combat.personaje.get_node("ProgressBarJ").visible, "No se muestra la barra gris duplicada")
	combat.personaje.staminaActual = 0
	combat.updateSkills()
	check(combat.aviso_turno.visible, "Sin stamina muestra la tecla E")
	combat.enemigo_actual.stun = 1
	var key := InputEventAction.new()
	key.action = "interactuar"
	key.pressed = true
	root.push_input(key)
	await process_frame
	check(combat.personaje.staminaActual > 0 and not combat.aviso_turno.visible, "Pasar turno recarga stamina y oculta el aviso")
	combat.personaje.staminaActual = 99
	for card in hand.get_children():
		card.usada = true
	combat.updateSkills()
	check(combat.aviso_turno.visible, "Todas usadas muestra E aunque quede stamina")
	hand.get_child(0).usada = false
	combat.updateSkills()
	check(not combat.aviso_turno.visible, "Volver a tener una carta jugable oculta E")
	for card in hand.get_children():
		card.usada = false
	combat.personaje.staminaActual = 2
	combat.updateSkills()
	var all_parts = state.brazos_equipados.duplicate()
	for count in [1, 2, 4, 0]:
		state.brazos_equipados.assign(all_parts.slice(0, count))
		combat.reconstruirSkills()
		await process_frame
		check(hand.get_child_count() == count, "Recoloca la mano con %d cartas" % count)
		if count == 1:
			check(is_zero_approx(hand.get_child(0).rotation), "Una carta queda recta")
	check(combat.aviso_turno.visible, "Mano vacía muestra E")
	combat.queue_free()
	await process_frame
	print("RESULTADO: ", errors, " fallos")
	quit(errors)
