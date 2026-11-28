extends SceneTree
var failures := 0
func verify(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
	else:
		print("OK: ", message)
func _initialize() -> void:
	call_deferred("run")
func mouse(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = pos
	event.global_position = pos
	event.pressed = pressed
	root.push_input(event)
func run() -> void:
	root.size = Vector2i(1152, 648)
	var state = root.get_node("EstadoPartida")
	state.brazos_equipados.assign([load("res://Recursos/partes/brazo_humano.tres"), load("res://Recursos/partes/brazo_ak47.tres")])
	var combat = load("res://escenas/Combate.tscn").instantiate()
	root.add_child(combat)
	combat.enemigo_actual.configurar_apariencia(1)
	for part in combat.enemigo_actual.partes:
		part.carta_soltada.connect(combat._on_carta_soltada)
	for i in 4:
		await process_frame
	var card = combat.contenedor.get_child(0)
	verify(card.get_node("VBoxContainer/Nombre").text == card.parte_origen.nombre, "El título es el nombre de la pieza")
	verify(card.get_node("VBoxContainer/Coste").text == str(card.staSkill), "El coste solo muestra el número")
	verify(card.get_node("VBoxContainer/Estado").text.is_empty(), "Una carta disponible no muestra instrucciones redundantes")
	var sibling = combat.contenedor.get_child(1)
	var pos: Vector2 = card.global_position
	var sibling_pos: Vector2 = sibling.global_position
	var texture = card.get_node("Fondo").texture
	verify(combat.get_node("PanelJugador").z_index > combat.get_node("Enemigo").z_index + 2, "La mano está por encima de todas las piezas del enemigo")
	verify(combat.get_node("Enemigo").z_index - 1 > 0, "El ala queda por delante del fondo del combate")
	# Begin an actual viewport drag, then let the card provide its preview.
	card.force_drag(card, null)
	card._get_drag_data(Vector2.ZERO)
	await process_frame
	var preview = root.find_child("VistaArrastreCarta", true, false)
	verify(preview != null and not preview.z_as_relative and preview.z_index == RenderingServer.CANVAS_ITEM_Z_MAX, "La vista de arrastre tiene su propio orden Z por encima de los enemigos")
	verify(root.gui_is_dragging(), "Arrastre activo en el viewport")
	verify(card.visible and not card.get_node("Fondo").visible and not card.get_node("VBoxContainer").visible, "La carta de la mano no se dibuja durante el arrastre")
	verify(card.global_position == pos and sibling.global_position == sibling_pos, "La mano mantiene los huecos durante el arrastre")
	card.updateDisponibilidad(0)
	verify(not card.get_node("Fondo").visible, "Actualizar stamina no hace reaparecer la carta arrastrada")
	mouse(Vector2(1100, 40), false)
	await process_frame
	verify(not root.gui_is_dragging() and card.get_node("Fondo").visible and card.get_node("VBoxContainer").visible, "Soltar fuera devuelve la carta a la mano")
	verify(card.get_node("Fondo").texture == texture, "Cancelar conserva el PNG elegido")
	verify(card.modulate == Color(0.55, 0.55, 0.55), "Cancelar conserva el estado de disponibilidad")
	var renewable = combat.contenedor.get_child(1)
	combat.personaje.staminaActual = 2
	combat.updateSkills()
	renewable.force_drag(renewable, null)
	renewable._get_drag_data(Vector2.ZERO)
	var movement := InputEventMouseMotion.new()
	movement.position = Vector2(590, 200)
	root.push_input(movement)
	mouse(Vector2(590, 200), false)
	await process_frame
	var replacement = combat.contenedor.get_child(1)
	verify(not is_instance_valid(renewable) or replacement != renewable, "Soltar sobre el enemigo juega y renueva la carta")
	verify(replacement.get_node("Fondo").visible and replacement.get_node("VBoxContainer").visible, "La carta renovada aparece visible en la mano")
	combat.queue_free()
	await process_frame
	print("RESULTADO: ", failures, " fallos")
	quit(failures)
