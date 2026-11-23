class_name Enemigo
extends Node2D
@onready var barra_vida: ProgressBar = $ProgressBar
var partes: Array[ParteEnemigo]
var dmg: int = 10
@export_enum("Enemigo 1", "Enemigo 2") var tipo_enemigo: int = 0
@export_group("Fichas de enemigos")
@export var ficha_enemigo_1: FichaEnemigo
@export var ficha_enemigo_2: FichaEnemigo
@export_group("Estados de combate")
@export var stun: int = 0
@export var debilContador: int = 0
@export var debilEstado: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	partes.assign([$Objetivo])
	configurar_apariencia(tipo_enemigo)
	actualizar_barra()


func configurar_apariencia(tipo: int) -> void:
	tipo_enemigo = tipo
	$Objetivo/Enemigo1.visible = tipo == 0
	$Objetivo/Enemigo2.visible = tipo == 1
	var ficha := ficha_enemigo_2 if tipo == 1 else ficha_enemigo_1
	if ficha != null:
		dmg = ficha.dano
		$Objetivo.vidaMax = ficha.vida_maxima
		$Objetivo.vidaActual = ficha.vida_maxima
	actualizar_barra()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func actualizar_barra() -> void:
	var vida_max_total := 0
	var vida_actual_total := 0
	for parte in partes:
		vida_max_total += parte.vidaMax
		vida_actual_total += parte.vidaActual
	barra_vida.max_value = vida_max_total
	barra_vida.value = vida_actual_total

func turno(objetivo: Personaje) -> void:
	#checkea si el enemigo está débil y actualiza los valores
	if debilContador > 0:
		debilEstado = 1
		debilContador = debilContador - 1
	else:
		debilEstado = 0
	
	if stun == 0:
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	else:
		stun = stun - 1 
