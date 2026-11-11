extends CanvasLayer

@export var camara: Camera3D
@export var jugador: Node3D
@export_range(0.5, 20.0, 0.5) var distancia_maxima: float = 6.0

@onready var boton: Button = $Examinar
@onready var aviso: PanelContainer = $Aviso
@onready var texto: Label = $Aviso/Texto
@onready var temporizador: Timer = $Temporizador

var objetivo: ObjetoExaminable
var clic_pendiente: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boton.hide()
	aviso.hide()
	boton.pressed.connect(_solicitar_examinar)
	temporizador.timeout.connect(aviso.hide)


func _solicitar_examinar() -> void:
	clic_pendiente = true


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(camara) or not is_instance_valid(jugador):
		_ocultar_boton()
		clic_pendiente = false
		return

	if (
		get_tree().paused
		or jugador.get("moviendo") == true
		or jugador.get("girando") == true
		or jugador.get("movimiento_pendiente") != 0
	):
		clic_pendiente = false
		_ocultar_boton()
		return

	# Las consultas al espacio físico se hacen en el paso de física.
	if clic_pendiente:
		clic_pendiente = false
		if is_instance_valid(objetivo) and _es_accesible(objetivo):
			_recoger(objetivo)
		_ocultar_boton()
		return

	var raton := get_viewport().get_mouse_position()
	# Mantener el objetivo permite pasar del objeto a su botón.
	if (
		boton.visible
		and boton.get_global_rect().has_point(raton)
		and is_instance_valid(objetivo)
		and _es_accesible(objetivo)
	):
		return

	var origen := camara.project_ray_origin(raton)
	var direccion := camara.project_ray_normal(raton)
	var impacto := _lanzar_rayo(origen, origen + direccion * distancia_maxima)
	var candidato := impacto.get("collider") as ObjetoExaminable
	if candidato == null or not _es_accesible(candidato):
		_ocultar_boton()
		return

	objetivo = candidato
	boton.show()
	var punto := camara.unproject_position(objetivo.punto_interaccion())
	var limite := get_viewport().get_visible_rect().size - boton.size
	boton.position = (punto - boton.size / 2.0).clamp(Vector2.ZERO, limite.max(Vector2.ZERO))


func _lanzar_rayo(origen: Vector3, destino: Vector3) -> Dictionary:
	# Capa 1: obstáculos. Capa 8: zonas examinables (sin bloquear movimiento).
	var mascara := 1 | (1 << 7)
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino, mascara)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = true
	return camara.get_world_3d().direct_space_state.intersect_ray(consulta)


func _es_accesible(objeto: ObjetoExaminable) -> bool:
	if not objeto.disponible():
		return false
	var origen := camara.global_position
	var destino := objeto.punto_interaccion()
	if origen.distance_to(destino) > distancia_maxima or camara.is_position_behind(destino):
		return false
	return _lanzar_rayo(origen, destino).get("collider") == objeto


func _recoger(objeto: ObjetoExaminable) -> void:
	var resultado := EstadoPartida.recoger_parte(objeto.id_objeto, objeto.recompensa)
	match resultado:
		"ok":
			texto.text = "Has encontrado %s y se ha agregado a tu SHIFT." % objeto.recompensa.nombre
		"lleno":
			texto.text = "Tu SHIFT está lleno. Haz espacio para recoger esta pieza."
		_:
			return
	aviso.show()
	temporizador.start()


func _ocultar_boton() -> void:
	boton.hide()
	objetivo = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		clic_pendiente = false
		_ocultar_boton()
