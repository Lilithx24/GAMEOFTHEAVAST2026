class_name ObjetoExaminable
extends Area3D

@export var id_objeto: String = ""
@export var recompensa: ParteInventario


func punto_interaccion() -> Vector3:
	# La colisión puede moverse en el editor sin mover el origen del Area3D.
	var colision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	return colision.global_position if colision != null else global_position


func disponible() -> bool:
	return (
		not id_objeto.is_empty()
		and recompensa != null
		and not EstadoPartida.fue_examinado(id_objeto)
	)
