class_name BrazoInventario
extends ParteInventario

@export var nombreSkill: String
@export var dmgSkill: int
@export var staSkill: int
@export var usosTotales: int
@export var efectos: Array[String]
## Consume la carta y la sustituye por otra igual después de resolver el ataque.
@export var renueva_carta_al_usar: bool = false

var usosRestantes: int = -1   


func usos_actuales() -> int:
	if usosRestantes < 0:
		usosRestantes = usosTotales
	return usosRestantes


func gastar_uso() -> void:
	usosRestantes = maxi(usos_actuales() - 1, 0)
