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

const PARTE_ENEMIGO := preload("res://escenas/assetsCombate/assetsEnemigo/parteEnemigo.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	configurar_apariencia(tipo_enemigo)


func configurar_apariencia(tipo: int) -> void:
	for p in partes:
		if is_instance_valid(p):
			remove_child(p)
			p.queue_free()
	partes.clear()
	
	tipo_enemigo = tipo
	$Objetivo/Enemigo1.visible = tipo == 0
	$Objetivo/Enemigo2.visible = tipo == 1
	var ficha := ficha_enemigo_2 if tipo == 1 else ficha_enemigo_1
	if ficha != null:
#		$Objetivo.vidaMax = ficha.vida_maxima
#		$Objetivo.vidaActual = ficha.vida_maxima
		for parte in ficha.partes:
			partes.append(crearPartes(parte))
	actualizar_barra()
	
##### Instanciar las partes #####
func crearPartes(DataParte: DatosParte) -> ParteEnemigo:
	var parte: ParteEnemigo = PARTE_ENEMIGO.instantiate()
	parte.datos = DataParte
	parte.vidaActual = DataParte.vidaMax
	add_child(parte)
	return parte

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func actualizar_barra() -> void:
	var vida_max_total := 0
	var vida_actual_total := 0
	for parte in partes:
		vida_max_total += parte.datos.vidaMax
		vida_actual_total += parte.vidaActual
	barra_vida.max_value = vida_max_total
	barra_vida.value = vida_actual_total

func turno(objetivo: Personaje) -> void:
	#checkea si el enemigo está débil y actualiza los valores
	if debilContador > 0:
		debilEstado = 1
		debilContador -= 1
	else:
		debilEstado = 0
	if stun == 0:
		var brazo_elegido := parte_brazo_aleatoria()
		if brazo_elegido == null:
			return
		var marioneta := $Objetivo/Enemigo2 if tipo_enemigo == 1 else $Objetivo/Enemigo1
		var animacion: AnimationPlayer = marioneta.get_node("AnimationPlayer")
		# La animación ya existe en las escenas de ambos enemigos.
		animacion.play("asalto", -1, 2.0)
		await get_tree().create_timer(0.12).timeout
		await ataque(objetivo, brazo_elegido.datos.dmg, brazo_elegido.datos.efectos)
		if animacion.is_playing():
			await animacion.animation_finished
		animacion.play("RESET")
		animacion.advance(0)
		animacion.stop()
	else:
		stun = stun - 1 
		
###### funciones auxiliares a turno ######
func parte_brazo_aleatoria() -> ParteEnemigo:
	var brazos: Array[ParteEnemigo] = []
	for parte in partes:
		if parte.datos.tags.has("brazo"):
			brazos.append(parte)
	if brazos.is_empty():
		return null
	return brazos.pick_random()


func ataque(objetivo: Personaje, dmg: int, efectos: Array[String]) -> void:
	if "sanacion" in efectos:
		for parte in partes:
			parte.setVidaActual(parte.vidaActual + dmg)
		actualizar_barra()
	else:
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	if "multihit2" in efectos:
		await get_tree().create_timer(0.1).timeout
		if objetivo.vidaActual <= 0:
			return
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	if "multihit3" in efectos:
		await get_tree().create_timer(0.1).timeout
		if objetivo.vidaActual <= 0:
			return
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
		await get_tree().create_timer(0.1).timeout
		if objetivo.vidaActual <= 0:
			return
		objetivo.sufrirDmg(dmg*(1 - 0.25 * debilEstado))
	if "debil" in efectos:
		objetivo.debilContador = objetivo.debilContador + 1
	if "stun" in efectos:
		objetivo.stun = objetivo.stun + 1
	if "atrapar" in efectos:
		if not objetivo.estados.has("atrapado"):
			objetivo.estados.append("atrapado")
