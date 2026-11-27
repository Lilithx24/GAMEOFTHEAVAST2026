extends Resource

const POOLS = [
	preload("res://Recursos/pools/torsos.tres"),
	preload("res://Recursos/pools/brazos.tres"),
	preload("res://Recursos/pools/cabezas.tres"),
	preload("res://Recursos/pools/piernas.tres"),
]

var ofertas: Array[ParteInventario] = []
var victorias_al_intercambiar: int = -1

func disponible(estado: Node) -> bool:
	return victorias_al_intercambiar < 0 or estado.enemigos_derrotados.size() > victorias_al_intercambiar

func preparar(estado: Node) -> Array[ParteInventario]:
	if not disponible(estado):
		return []
	if ofertas.is_empty():
		var nuevas: Array[ParteInventario] = []
		for pool in POOLS:
			var parte: ParteInventario = pool.sortear()
			if parte == null:
				return []
			nuevas.append(parte)
		ofertas = nuevas
	return ofertas

func entregar(estado: Node, zona: String, indice: int, pieza: ParteInventario, opcion: int) -> bool:
	if not disponible(estado) or opcion < 0 or opcion >= ofertas.size():
		return false
	if zona not in ["inventario", "temporal"]:
		return false
	if pieza == null or estado.parte_en(zona, indice) != pieza:
		return false
	var recibida := ofertas[opcion].duplicate(true) as ParteInventario
	# Reemplazar en el mismo hueco permite intercambiar con SHIFT lleno.
	if zona == "inventario":
		estado.inventario[indice] = recibida
	elif zona == "temporal":
		estado.inventario_temporal[indice] = recibida
	victorias_al_intercambiar = estado.enemigos_derrotados.size()
	ofertas.clear()
	estado.inventario_cambiado.emit()
	return true

func reiniciar() -> void:
	ofertas.clear()
	victorias_al_intercambiar = -1
