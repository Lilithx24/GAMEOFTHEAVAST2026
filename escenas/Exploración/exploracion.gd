extends Node3D

@onready var jugador = $PisoCero/Jugador
@onready var punto_combate = $PisoCero/PuntosExploracion/Punto10
@onready var enemigo_visual = $PisoCero/EnemigoExploracion


func _ready() -> void:
	if EstadoPartida.volver_de_combate:
		jugador.global_transform = EstadoPartida.transform_jugador
		EstadoPartida.volver_de_combate = false

	if EstadoPartida.enemigo_derrotado:
		enemigo_visual.queue_free()

	jugador.punto_alcanzado.connect(_on_punto_alcanzado)


func _on_punto_alcanzado(punto: Node3D) -> void:
	if punto == punto_combate and not EstadoPartida.enemigo_derrotado:
		EstadoPartida.transform_jugador = jugador.global_transform
		get_tree().change_scene_to_file("res://escenas/Combate.tscn")
