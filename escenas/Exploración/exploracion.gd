extends Node3D

@onready var jugador = $PisoCero/Jugador


func _ready() -> void:
	if EstadoPartida.volver_de_combate or EstadoPartida.volver_de_intercambio:
		jugador.global_transform = EstadoPartida.transform_jugador
		EstadoPartida.volver_de_combate = false
		EstadoPartida.volver_de_intercambio = false

	for enemigo in get_tree().get_nodes_in_group("enemigos_exploracion"):
		if EstadoPartida.enemigos_derrotados.has(enemigo.identificador()):
			enemigo.hide()
			enemigo.collision_layer = 0
			enemigo.queue_free()

	jugador.enemigo_detectado.connect(_on_enemigo_detectado)


func _on_enemigo_detectado(enemigo: Node3D) -> void:
	if not EstadoPartida.enemigos_derrotados.has(enemigo.identificador()) and not TransicionCombate.en_curso:
		EstadoPartida.enemigo_actual_id = enemigo.identificador()
		EstadoPartida.tipo_enemigo_actual = enemigo.tipo_enemigo
		EstadoPartida.transform_jugador = jugador.global_transform
		TransicionCombate.iniciar(self, jugador.get_node("Camera3D"), jugador.get_node("Gestor de Audio/Musica"), enemigo)
