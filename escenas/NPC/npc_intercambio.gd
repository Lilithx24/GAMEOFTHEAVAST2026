extends Node3D

@export var textos: TextosIntercambio = preload("res://Recursos/textos_intercambio.tres")

func _ready() -> void:
	$Dialogo.theme = preload("res://escenas/NPC/estilo_intercambio.gd").crear_tema()
	$Dialogo.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Dialogo.get_label().custom_minimum_size = Vector2(480, 80)
	$Dialogo.title = textos.titulo_dialogo
	$Dialogo.ok_button_text = textos.volver


var entrando := false
var pausa_anterior := false
var menu: Node

func punto_interaccion() -> Vector3:
	return $Cuerpo.global_position

func puede_interactuar_con(cuerpo: Node3D) -> bool:
	return cuerpo == $Cuerpo and not entrando and not $Dialogo.visible

func interactuar() -> void:
	if entrando or $Dialogo.visible:
		return
	if not EstadoPartida.intercambio_npc.disponible(EstadoPartida):
		pausa_anterior = get_tree().paused
		get_tree().paused = true
		menu = get_tree().current_scene.get_node_or_null("MenuShift")
		if menu != null:
			menu.set_process_input(false)
		$Dialogo.dialog_text = textos.espera
		$Dialogo.popup_centered(Vector2i(620, 200))
		return
	entrando = true
	_entrar.call_deferred()

func _entrar() -> void:
	var jugador = get_tree().current_scene.get_node("PisoCero/Jugador")
	EstadoPartida.transform_jugador = jugador.global_transform
	EstadoPartida.volver_de_intercambio = true
	var error := get_tree().change_scene_to_file("res://escenas/NPC/Intercambio.tscn")
	if error != OK:
		EstadoPartida.volver_de_intercambio = false
		entrando = false
		push_error("No se pudo abrir el intercambio: " + error_string(error))

func _cerrar_dialogo() -> void:
	get_tree().paused = pausa_anterior
	if is_instance_valid(menu):
		menu.set_process_input(true)
