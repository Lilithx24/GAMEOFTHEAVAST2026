class_name PoolPartes
extends Resource

@export_enum("torso", "brazo", "cabeza", "piernas") var tipo: String = "torso"
@export var partes: Array[ParteInventario] = []


func candidatas() -> Array[ParteInventario]:
	var resultado: Array[ParteInventario] = []
	for parte in partes:
		if parte != null and parte.tags.has(tipo):
			resultado.append(parte)
	return resultado


func sortear() -> ParteInventario:
	var opciones := candidatas()
	return null if opciones.is_empty() else opciones.pick_random()
