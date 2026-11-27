class_name ParteEnemigo
extends TextureRect

@export var datos: DatosParte   # los datos ahora vienen de un recurso
var vidaActual: int

signal carta_soltada(skill: Skill, parte: ParteEnemigo)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func sufrirDmg(damage: int):
	var probImpacto: int = (100 - datos.evasion)
	var tiradaAtaque: int = randi() % 100
	if tiradaAtaque < probImpacto || "atrapado" in datos.estados:
		var reduccion: float = datos.proteccion / 100.0          
		var danoFinal: float = damage * (1.0 - reduccion)  
		var nuevaVida = setVidaActual(vidaActual - danoFinal)
		print("vida restante: ", nuevaVida)

func setVidaActual(vida: int) -> int:
	vidaActual = clampi(vida, 0, datos.vidaMax) #Esta mierda es pa que no baje de 0
	return vidaActual

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Skill

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	carta_soltada.emit(data, self)
