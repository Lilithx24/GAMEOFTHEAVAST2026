class_name Combate
extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")
const ESCENA_ENEMIGO := preload("res://escenas/assetsCombate/enemigo.tscn")
const ESCENA_PARTE_ENEMIGO := preload("res://escenas/assetsCombate/assetsEnemigo/parteEnemigo.tscn")
const ESCENA_PERSONAJE := preload("res://escenas/assetsCombate/personaje.tscn")
const ESCENA_PARTE_PERSONAJE := preload("res://escenas/assetsCombate/assetsPersonaje/partePersonaje.tscn")
const ESCENA_MUERTE := preload("res://escenas/PantallaMuerte/pantallaMuerte.tscn")

var parteEnemigaSeleccionada: ParteEnemigo
var enemigo_actual: Enemigo
var personaje: Personaje
var combate_terminado: bool = false
var partes_usadas: Dictionary = {}
var skillSolicitada: bool = false
@onready var contenedor = $PanelJugador/ScrollContainer/HBoxContainer
@onready var contador_stamina: Control = $PanelJugador/CanvasLayer/ContadorStamina

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contenedor = $PanelJugador/ScrollContainer/HBoxContainer
	var parteEnemigoA = crearParteEnemigo(100)
	enemigo_actual = crearEnemigo([parteEnemigoA])
	personaje = crearPersonaje(EstadoPartida.obtener_vida_maxima(), [])
	EstadoPartida.inventario_cambiado.connect(_solicitar_skills)
	reconstruirSkills()
	personaje.staminaActual = personaje.stamina
	updateSkills()
	personaje.murio.connect(_on_personaje_murio)


func _solicitar_skills() -> void:
	skillSolicitada = true


# Solo cuando cambia el equipo (y al empezar el combate)
func reconstruirSkills() -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()

	for parte in EstadoPartida.brazos_equipados:
		var brazo := parte as BrazoInventario   # null si el hueco está vacío o no es un brazo
		if brazo == null:
			continue
		var carta := crearSkill(brazo.nombreSkill, brazo.dmgSkill, brazo.staSkill, brazo, brazo.efectos)
		if partes_usadas.has(brazo):
			carta.marcarUsada()


	var cabeza: ParteInventario = EstadoPartida.equipo["cabeza"]
	var piernas: ParteInventario = EstadoPartida.equipo["piernas"]
	var torso: ParteInventario = EstadoPartida.equipo["torso"]

	###### aplicar los bufos a las estadísticas de los items ######
	personaje.stamina = personaje.staminaBase + stat(cabeza, "stamina") + stat(piernas, "stamina")
	personaje.evasion =  stat(cabeza, "evasion") + stat(piernas, "evasion")
	personaje.proteccion = stat(cabeza, "proteccion") + stat(piernas, "proteccion") + stat(torso, "proteccion")
	personaje.modDmg = stat(cabeza, "modDmg") + stat(piernas, "modDmg")

	updateSkills()
	
	
###### Funciones de instanciamiento ######

func crearEnemigo(partes: Array[ParteEnemigo]) -> Enemigo:
	enemigo_actual = ESCENA_ENEMIGO.instantiate()
	add_child(enemigo_actual)
	enemigo_actual.partes = partes
	for parte in partes:
		enemigo_actual.add_child(parte)
		parte.carta_soltada.connect(_on_carta_soltada)
	enemigo_actual.actualizar_barra()
	return enemigo_actual

func crearParteEnemigo(vida: int) -> ParteEnemigo:
	var parteEnemigo: ParteEnemigo = ESCENA_PARTE_ENEMIGO.instantiate()
	parteEnemigo.vidaMax = vida
	parteEnemigo.vidaActual = parteEnemigo.vidaMax
	parteEnemigo.vital = true
	return parteEnemigo

func crearPersonaje(vida: int,partes: Array[PartePersonaje]) -> Personaje:
	var personaje: Personaje = ESCENA_PERSONAJE.instantiate()
	add_child(personaje)
	personaje.vidaMax = vida
	personaje.vidaActual = personaje.vidaMax
	personaje.actualizar_barra()
	personaje.partes = partes
	return personaje

#func crearPartePersonaje(skills: Array[Skill]) -> PartePersonaje:
#	var partePersonaje: PartePersonaje = ESCENA_PARTE_PERSONAJE.instantiate()
#	partePersonaje.skills = skills
#	return partePersonaje


func crearSkill(nombre: String, dmg: int, sta: int, origen: BrazoInventario = null, efectos: Array[String] = []) -> Skill:
	var skill: Skill = ESCENA_SKILL.instantiate()
	skill.parte_origen = origen
	skill.nombreSkill= nombre
	skill.dmgSkill = dmg
	skill.staSkill = sta
	skill.efectos = efectos
	contenedor.add_child(skill)
	return skill

###### Fin funciones instanciamiento ######

func _on_carta_soltada(skill: Skill, parte: ParteEnemigo) -> void:
	if combate_terminado or not skill.disponible or skill.usada:
		return
	if skill.get_parent() != contenedor or skill.staSkill > personaje.staminaActual:
		return
	if skill.parte_origen and not EstadoPartida.brazos_equipados.has(skill.parte_origen):
		return
	if skill.parte_origen:
		partes_usadas[skill.parte_origen] = true
	parteEnemigaSeleccionada = parte
	skill.marcarUsada()
	_onSkillElegida(skill.dmgSkill + personaje.modDmg, skill.staSkill, skill.efectos)

func _onSkillElegida(dmg: int, sta: int, efectos: Array[String]) -> void:
	if combate_terminado:
		return
	parteEnemigaSeleccionada.sufrirDmg(dmg)
	enemigo_actual.actualizar_barra()
	if "multihit2" in efectos:
		await get_tree().create_timer(0.1).timeout
		parteEnemigaSeleccionada.sufrirDmg(dmg)
		enemigo_actual.actualizar_barra()
	if "multihit3" in efectos:
		await get_tree().create_timer(0.1).timeout
		parteEnemigaSeleccionada.sufrirDmg(dmg)
		enemigo_actual.actualizar_barra()
		await get_tree().create_timer(0.1).timeout
		parteEnemigaSeleccionada.sufrirDmg(dmg)
		enemigo_actual.actualizar_barra()
	if "debil" in efectos:
		enemigo_actual.debilContador = enemigo_actual.debilContador + 1
	if "stun" in efectos:
		enemigo_actual.stun = enemigo_actual.stun + 1
	personaje.staminaActual -= sta
	personaje.actualizar_barra()
	if parteEnemigaSeleccionada.vidaActual == 0 \
			and parteEnemigaSeleccionada.vital:
		ganarCombate()
		return
	updateSkills()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		terminarTurno()

func terminarTurno() -> void:
	if combate_terminado:
		return
	enemigo_actual.turno(personaje)
	partes_usadas.clear()
	personaje.actualizar_barra()
	for hijo in contenedor.get_children():
		if hijo is Skill:
			hijo.recuperar()
	if skillSolicitada == true:
		reconstruirSkills()
		skillSolicitada = false
	personaje.staminaActual = personaje.stamina
	updateSkills()


func updateSkills() -> void:
	contador_stamina.actualizar(personaje.staminaActual)
	for hijo in contenedor.get_children():
		if hijo is Skill:
			hijo.updateDisponibilidad(personaje.staminaActual)

func stat(pieza: ParteInventario, nombre: String):
	if pieza == null:
		return 0
	var valor = pieza.get(nombre)
	return valor if valor != null else 0

func ganarCombate() -> void:
	combate_terminado = true
	EstadoPartida.enemigo_derrotado = true
	EstadoPartida.volver_de_combate = true
	get_tree().change_scene_to_file(
		"res://escenas/Exploración/Pisos/PlantaCero.tscn"
	)

func _on_personaje_murio() -> void:
	if combate_terminado:
		return
	combate_terminado = true   # bloquea cartas y fin de turno
	var pantalla := ESCENA_MUERTE.instantiate()
	add_child(pantalla)
	pantalla.reiniciarNivel.connect(EstadoPartida.reiniciarNivel)
	get_tree().paused = true

func _on_button_pressed() -> void:
	pass # Replace with function body.
