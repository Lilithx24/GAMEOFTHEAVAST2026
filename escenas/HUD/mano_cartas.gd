@tool
extends Control

## Ajustes del abanico editables desde la escena de combate.
@export_range(40.0, 180.0) var separacion: float = 112.0
@export_range(0.0, 25.0) var angulo_maximo: float = 12.0
@export_range(0.0, 80.0) var caida_lateral: float = 28.0
@export_range(0.0, 80.0) var elevar_al_apuntar: float = 36.0

var enfocada: Control

func _ready() -> void:
	child_order_changed.connect(ordenar)
	resized.connect(ordenar)
	ordenar()

func _base(indice: int, cantidad: int, carta: Control) -> Dictionary:
	var centro := (cantidad - 1) * 0.5
	var paso := minf(separacion, maxf(0.0, size.x - carta.size.x - 64.0) / maxf(1.0, cantidad - 1))
	var factor := (indice - centro) / maxf(centro, 1.0)
	return {
		"posicion": Vector2((size.x - carta.size.x) * 0.5 + (indice - centro) * paso, caida_lateral * factor * factor),
		"angulo": deg_to_rad(angulo_maximo) * factor if cantidad > 1 else 0.0,
	}

func ordenar() -> void:
	if not is_instance_valid(enfocada) or enfocada.get_parent() != self:
		enfocada = null
	var cartas := get_children()
	for i in cartas.size():
		var carta := cartas[i] as Control
		if carta == null:
			continue
		carta.size = carta.custom_minimum_size
		carta.pivot_offset = carta.size * 0.5
		var base := _base(i, cartas.size(), carta)
		carta.position = base.posicion
		carta.rotation = base.angulo
		carta.z_index = i
		if carta == enfocada:
			carta.position.y -= elevar_al_apuntar
			carta.rotation = 0.0
			carta.z_index = cartas.size() + 1
		if not Engine.is_editor_hint():
			carta.mouse_filter = Control.MOUSE_FILTER_STOP if carta == enfocada else Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not event is InputEventMouseMotion or get_viewport().gui_is_dragging():
		return
	var candidata: Control
	var cartas := get_children()
	var raton: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	# Usar las posiciones de reposo evita que la carta salte al elevarla.
	for i in range(cartas.size() - 1, -1, -1):
		var carta := cartas[i] as Control
		if carta == null:
			continue
		var base := _base(i, cartas.size(), carta)
		var transformacion := Transform2D(base.angulo, base.posicion + carta.size * 0.5)
		var local := transformacion.affine_inverse() * raton + carta.size * 0.5
		if Rect2(Vector2.ZERO, carta.size).has_point(local):
			candidata = carta
			break
	if candidata == null and is_instance_valid(enfocada) and enfocada.get_parent() == self:
		if Rect2(enfocada.position, enfocada.size).has_point(raton):
			candidata = enfocada
	if candidata != enfocada:
		enfocada = candidata
		ordenar()
