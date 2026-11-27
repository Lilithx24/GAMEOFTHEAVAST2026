extends ObjetoExaminable

const POOLS = [
	preload("res://Recursos/pools/torsos.tres"),
	preload("res://Recursos/pools/brazos.tres"),
	preload("res://Recursos/pools/cabezas.tres"),
	preload("res://Recursos/pools/piernas.tres"),
]

@export_enum("Torsos", "Brazos", "Cabezas", "Piernas") var tipo_parte: int = 0


func _ready() -> void:
	# La ruta diferencia también las cajas duplicadas desde el editor.
	if id_objeto.is_empty():
		id_objeto = str(get_path())
	add_to_group("cajas_plastico")


func disponible() -> bool:
	return not id_objeto.is_empty() and not EstadoPartida.fue_examinado(id_objeto) and not POOLS[tipo_parte].candidatas().is_empty()


func obtener_recompensa() -> ParteInventario:
	# Mantener el resultado si SHIFT está lleno o se vuelve a cargar el mapa.
	if not EstadoPartida.recompensas_cajas.has(id_objeto):
		var parte: ParteInventario = POOLS[tipo_parte].sortear()
		if parte != null:
			EstadoPartida.recompensas_cajas[id_objeto] = parte
	return EstadoPartida.recompensas_cajas.get(id_objeto)
