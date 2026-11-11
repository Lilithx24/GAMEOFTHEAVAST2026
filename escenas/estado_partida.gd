extends Node
signal inventario_cambiado

var objetos_examinados: Dictionary = {}

var transform_jugador: Transform3D
var volver_de_combate: bool = false
var enemigo_derrotado: bool = false

var inventario_inicializado: bool = false

var inventario: Array[ParteInventario] = []

# Los huecos adicionales solo existen mientras contienen una pieza devuelta.
var inventario_temporal: Dictionary = {}
var siguiente_hueco_temporal: int = 0

var equipo: Dictionary = {
	"cabeza": null,
	"torso": null,
	"piernas": null
}

var brazos_equipados: Array[ParteInventario] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func obtener_capacidad_brazos() -> int:
	var torso := equipo["torso"] as TorsoInventario

	if torso == null:
		return 0

	return clampi(torso.slotsBrazos, 2, 8)

func inicializar_inventario(items: Array[ParteInventario]) -> void:
	if inventario_inicializado:
		return

	inventario.resize(20)

	for i in mini(items.size(), inventario.size()):
		inventario[i] = items[i]

	inventario_inicializado = true


func fue_examinado(id_objeto: String) -> bool:
	return objetos_examinados.has(id_objeto)


func recoger_parte(id_objeto: String, parte: ParteInventario) -> String:
	if id_objeto.is_empty() or parte == null:
		return "error"
	if fue_examinado(id_objeto):
		return "recogido"

	var items_vacios: Array[ParteInventario] = []
	inicializar_inventario(items_vacios)
	var hueco := inventario.find(null)
	if hueco == -1:
		return "lleno"

	# Un ejemplar independiente por hallazgo, también para sus futuros usos.
	inventario[hueco] = parte.duplicate(true) as ParteInventario
	objetos_examinados[id_objeto] = true
	inventario_cambiado.emit()
	return "ok"


func parte_en(zona: String, indice: int = 0) -> ParteInventario:
	match zona:
		"inventario":
			return inventario[indice] if indice >= 0 and indice < inventario.size() else null
		"temporal":
			return inventario_temporal.get(indice)
		"brazo":
			return brazos_equipados[indice] if indice >= 0 and indice < brazos_equipados.size() else null
		_:
			return equipo.get(zona)


func admite_parte(parte: ParteInventario, posicion: String, indice: int = 0) -> bool:
	if parte == null:
		return false
	match posicion:
		"torso":
			return parte is TorsoInventario and parte.tags.has("torso")
		"cabeza", "piernas":
			return equipo["torso"] != null and parte.tags.has(posicion)
		"brazo":
			return indice >= 0 and indice < obtener_capacidad_brazos() and parte.tags.has("brazo")
	return false


func puede_equipar(origen: String, indice_origen: int, destino: String, indice_destino: int) -> bool:
	if origen == destino and indice_origen == indice_destino:
		return false
	var pieza := parte_en(origen, indice_origen)
	if not admite_parte(pieza, destino, indice_destino):
		return false
	# Entre enganches solo se intercambian brazos compatibles.
	if origen != "inventario" and origen != "temporal":
		return origen == "brazo" and destino == "brazo"
	return true


func equipar_parte(origen: String, indice_origen: int, destino: String, indice_destino: int = 0) -> bool:
	if not puede_equipar(origen, indice_origen, destino, indice_destino):
		return false
	var pieza := parte_en(origen, indice_origen)
	var anterior := parte_en(destino, indice_destino)
	_quitar_de(origen, indice_origen)
	_poner_equipo(destino, indice_destino, pieza)
	if origen == "brazo":
		_poner_equipo(origen, indice_origen, anterior)
	elif anterior != null:
		_guardar_pieza_devuelta(anterior)
	_ajustar_a_torso()
	inventario_cambiado.emit()
	return true


func desequipar_parte(posicion: String, indice: int = 0) -> bool:
	if posicion not in ["cabeza", "torso", "piernas", "brazo"]:
		return false
	var pieza := parte_en(posicion, indice)
	if pieza == null:
		return false
	_quitar_de(posicion, indice)
	_guardar_pieza_devuelta(pieza)
	_ajustar_a_torso()
	inventario_cambiado.emit()
	return true


func _quitar_de(zona: String, indice: int) -> void:
	match zona:
		"inventario":
			inventario[indice] = null
		"temporal":
			inventario_temporal.erase(indice)
		_:
			_poner_equipo(zona, indice, null)


func _poner_equipo(posicion: String, indice: int, pieza: ParteInventario) -> void:
	if posicion == "brazo":
		if brazos_equipados.size() < 8:
			brazos_equipados.resize(8)
		brazos_equipados[indice] = pieza
	else:
		equipo[posicion] = pieza


func _guardar_pieza_devuelta(pieza: ParteInventario) -> void:
	var hueco := inventario.find(null)
	if hueco >= 0:
		inventario[hueco] = pieza
	else:
		inventario_temporal[siguiente_hueco_temporal] = pieza
		siguiente_hueco_temporal += 1


func _ajustar_a_torso() -> void:
	if equipo["torso"] == null:
		for posicion in ["cabeza", "piernas"]:
			var pieza: ParteInventario = equipo[posicion]
			if pieza != null:
				equipo[posicion] = null
				_guardar_pieza_devuelta(pieza)
	var capacidad := obtener_capacidad_brazos()
	for i in range(capacidad, brazos_equipados.size()):
		if brazos_equipados[i] != null:
			_guardar_pieza_devuelta(brazos_equipados[i])
			brazos_equipados[i] = null
