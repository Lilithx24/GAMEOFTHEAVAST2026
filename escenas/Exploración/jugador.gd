extends Node3D
signal punto_alcanzado(punto: Node3D)
@export var duracion_giro: float = 0.25
@export var duracion_movimiento: float = 0.8
@onready var rayo_interaccion: RayCast3D = $Camera3D/RayoInteraccion

var girando: bool = false
var moviendo: bool = false
var movimiento_pendiente: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if girando or moviendo or movimiento_pendiente != 0:
		return
	if event.is_action_pressed("girar_izquierda"):
		girar(-1)
	elif event.is_action_pressed("girar_derecha"):
		girar(1)
	elif event.is_action_pressed("avanzar"):
		movimiento_pendiente = 1
	elif event.is_action_pressed("retroceder"):
		movimiento_pendiente = -1

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("interactuar"):
		if not girando and not moviendo and movimiento_pendiente == 0:
			intentar_interactuar()

	# Consultamos las colisiones durante el paso de física.
	if movimiento_pendiente != 0:
		mover(movimiento_pendiente)
		movimiento_pendiente = 0

# -1 gira a la izquierda; 1 gira a la derecha.
func girar(sentido: int) -> void:
	girando = true
	var rotacion_destino: float = rotation.y - sentido * PI / 2.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", rotacion_destino, duracion_giro)

	await tween.finished
	girando = false

func buscar_punto(sentido: int) -> Node3D:
	var direccion: Vector3 = -global_transform.basis.z * sentido
	direccion.y = 0.0
	direccion = direccion.normalized()
	var cercano: Node3D = null
	var distancia_menor: float = INF

	for punto: Node3D in get_tree().get_nodes_in_group("puntos_exploracion"):
		var diferencia: Vector3 = punto.global_position - global_position
		diferencia.y = 0.0
		var distancia: float = diferencia.dot(direccion)
		var desviacion: float = (diferencia - direccion * distancia).length()

		# Debe estar delante (o detrás con S), alineado y ser el más cercano.
		# Admitimos 5 cm de margen para colocar los marcadores en el editor.
		if distancia > 0.05 and desviacion <= 0.05 and distancia < distancia_menor:
			cercano = punto
			distancia_menor = distancia

	return cercano

func mover(sentido: int) -> void:
	var punto: Node3D = buscar_punto(sentido)
	if punto == null:
		return

	var destino: Vector3 = punto.global_position
	# Los marcadores están en el suelo: conservamos la altura del jugador.
	destino.y = global_position.y

	# Las paredes usan la capa de colisión 1.
	var consulta := PhysicsRayQueryParameters3D.create(global_position, destino, 1)
	if not get_world_3d().direct_space_state.intersect_ray(consulta).is_empty():
		return

	moviendo = true
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", destino, duracion_movimiento)

	await tween.finished
	moviendo = false
	punto_alcanzado.emit(punto)

func intentar_interactuar() -> void:
	rayo_interaccion.force_raycast_update()

	if not rayo_interaccion.is_colliding():
		return

	var cuerpo := rayo_interaccion.get_collider() as Node
	var nodo: Node = cuerpo

	while nodo != null:
		if nodo.has_method("interactuar"):
			# Solo se activa al mirar la hoja, no el marco.
			if nodo.get_node_or_null("Bisagra/Puerta/Cuerpo") == cuerpo:
				nodo.call("interactuar")
			return

		nodo = nodo.get_parent()
