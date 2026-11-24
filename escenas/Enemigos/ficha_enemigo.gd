class_name FichaEnemigo
extends Resource

@export var nombre: String = "Enemigo"
@export_range(1, 10000, 1) var vida_maxima: int = 100
@export_range(0, 500, 1) var dano: int = 10
