extends CanvasLayer

# Compartido entre instancias para no repetir tampoco al volver del combate.
static var ultimo_sonido_examinar: int = -1

@export var camara: Camera3D
@export var jugador: Node3D
@export_range(0.5, 20.0, 0.5) var distancia_maxima: float = 6.0

@onready var boton: Button = $Examinar
@onready var boton_interactuar: Button = $Interactuar
@onready var aviso: PanelContainer = $Aviso
@onready var texto: Label = $Aviso/Texto
@onready var temporizador: Timer = $Temporizador
@onready var sonidos_examinar: Array[AudioStreamPlayer] = [
	$SonidosExaminar/Examinar1,
	$SonidosExaminar/Examinar2,
	$SonidosExaminar/Examinar3,
]

var objetivo: ObjetoExaminable
var clic_pendiente: bool = false
var objetivo_interaccion: Node3D
var cuerpo_interaccion: Node3D
var punto_interaccion_local: Vector3
var interaccion_pendiente: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boton.hide()
	boton_interactuar.hide()
	aviso.hide()
	boton.pressed.connect(_solicitar_examinar)
	boton_interactuar.pressed.connect(_solicitar_interactuar)
	temporizador.timeout.connect(aviso.hide)


func _solicitar_examinar() -> void:
	clic_pendiente = true


func _solicitar_interactuar() -> void:
	interaccion_pendiente = true


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
	if interaccion_pendiente:
		interaccion_pendiente = false
		if _interaccion_accesible():
			objetivo_interaccion.call("interactuar")
		_ocultar_boton()
		return

	if clic_pendiente:
		clic_pendiente = false
		if is_instance_valid(objetivo) and _es_accesible(objetivo):
			_recoger(objetivo)
		_ocultar_boton()
		return

	var raton := get_viewport().get_mouse_position()
	if boton_interactuar.visible and boton_interactuar.get_global_rect().has_point(raton) and _interaccion_accesible():
		return
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
		_mostrar_interaccion(impacto)
		return

	boton_interactuar.hide()
	objetivo_interaccion = null
	objetivo = candidato
	boton.show()
	var punto := camara.unproject_position(objetivo.punto_interaccion())
	var limite := get_viewport().get_visible_rect().size - boton.size
	boton.position = (punto - boton.size / 2.0).clamp(Vector2.ZERO, limite.max(Vector2.ZERO))


func _mostrar_interaccion(impacto: Dictionary) -> void:
	var cuerpo := impacto.get("collider") as Node3D
	var candidato: Node = cuerpo
	while candidato != null:
		if candidato is Node3D and candidato.has_method("interactuar"):
			objetivo_interaccion = candidato
			cuerpo_interaccion = cuerpo
			punto_interaccion_local = cuerpo.to_local(impacto["position"])
			if not _interaccion_accesible():
				_ocultar_boton()
				return
			boton_interactuar.show()
			var posicion_cartel: Vector3 = cuerpo.global_position
			if candidato.has_method("punto_interaccion"):
				posicion_cartel = candidato.call("punto_interaccion")
			var punto := camara.unproject_position(posicion_cartel)
			var limite := get_viewport().get_visible_rect().size - boton_interactuar.size
			boton_interactuar.position = (punto - boton_interactuar.size / 2.0).clamp(Vector2.ZERO, limite.max(Vector2.ZERO))
			return
		candidato = candidato.get_parent()


func _interaccion_accesible() -> bool:
	if not is_instance_valid(objetivo_interaccion) or not is_instance_valid(cuerpo_interaccion):
		return false
	if objetivo_interaccion.has_method("puede_interactuar_con") and not objetivo_interaccion.call("puede_interactuar_con", cuerpo_interaccion):
		return false
	var origen := camara.global_position
	var destino := cuerpo_interaccion.to_global(punto_interaccion_local)
	if origen.distance_to(destino) > distancia_maxima or camara.is_position_behind(destino):
		return false
	# Prolongar ligeramente el rayo permite alcanzar la superficie seleccionada.
	return _lanzar_rayo(origen, destino + (destino - origen).normalized() * 0.02).get("collider") == cuerpo_interaccion


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
	_reproducir_sonido_examinar()
	aviso.show()
	temporizador.start()


func _reproducir_sonido_examinar() -> void:
	var opciones: Array[int] = []
	for indice in range(sonidos_examinar.size()):
		if indice != ultimo_sonido_examinar:
			opciones.append(indice)
	ultimo_sonido_examinar = opciones.pick_random()
	for sonido in sonidos_examinar:
		sonido.stop()
	sonidos_examinar[ultimo_sonido_examinar].play()


func _ocultar_boton() -> void:
	boton.hide()
	boton_interactuar.hide()
	objetivo = null
	objetivo_interaccion = null
	cuerpo_interaccion = null
	interaccion_pendiente = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		clic_pendiente = false
		_ocultar_boton()
