class_name Enemigo
extends Node2D
@onready var barra_vida: ProgressBar = $ProgressBar
var partes: Array[ParteEnemigo]
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
		var brazo_elegido := parte_brazo_aleatoria()
		ataque(objetivo, brazo_elegido.dmg, brazo_elegido.efectos)
	else:
		stun = stun - 1 
		
###### funciones auxiliares a turno ######
func parte_brazo_aleatoria() -> ParteEnemigo:
	var brazos: Array[ParteEnemigo] = []
	for parte in partes:
		if parte.tags.has("brazo"):
			brazos.append(parte)

	if brazos.is_empty():
		return null

	return brazos.pick_random()


func ataque(objetivo: Personaje, dmg: int, efectos: Array[String]) -> void:
	if "sanacion" in efectos:
		for parte in partes:
			parte.vidaActual = parte.vidaActual + dmg
			parte.actualizar_barra()
	else:
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	if "multihit2" in efectos:
		await get_tree().create_timer(0.1).timeout
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	if "multihit3" in efectos:
		await get_tree().create_timer(0.1).timeout
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
		await get_tree().create_timer(0.1).timeout
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	if "debil" in efectos:
		objetivo.debilContador = objetivo.debilContador + 1
	if "stun" in efectos:
		objetivo.stun = objetivo.stun + 1
	if "atrapar" in efectos:
		if not objetivo.estados.has("atrapado"):
			objetivo.estados.append("atrapado")
