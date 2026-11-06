extends CanvasLayer

var pausa_anterior: bool = false


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
