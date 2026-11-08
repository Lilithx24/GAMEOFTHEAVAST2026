class_name Combate
extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")
const ESCENA_ENEMIGO := preload("res://escenas/assetsCombate/enemigo.tscn")
const ESCENA_PARTE_ENEMIGO := preload("res://escenas/assetsCombate/assetsEnemigo/parteEnemigo.tscn")
const ESCENA_PERSONAJE := preload("res://escenas/assetsCombate/personaje.tscn")
const ESCENA_PARTE_PERSONAJE := preload("res://escenas/assetsCombate/assetsPersonaje/partePersonaje.tscn")

var parteEnemigaSeleccionada: ParteEnemigo
var enemigo_actual: Enemigo
var personaje: Personaje
var combate_terminado: bool = false
@onready var contenedor = $PanelJugador/HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contenedor = $PanelJugador/HBoxContainer
	var parteEnemigoA = crearParteEnemigo(100)
	enemigo_actual = crearEnemigo([parteEnemigoA])
	var skillA = crearSkill("Ataque 15 de daño", 15, 2)
	var partePersonajeA = crearPartePersonaje([skillA])
	var skillB = crearSkill("Ataque 10 de daño", 10, 1)
	var partePersonajeB = crearPartePersonaje([skillB])
	personaje = crearPersonaje(100, 2, [partePersonajeA,partePersonajeB])
	updateSkills()

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

func crearPersonaje(vida: int,stamina: int,partes: Array[PartePersonaje]) -> Personaje:
	var personaje: Personaje = ESCENA_PERSONAJE.instantiate()
	add_child(personaje)
	personaje.vidaMax = vida
	personaje.vidaActual = personaje.vidaMax
	personaje.staminaMax = stamina
	personaje.staminaActual = personaje.staminaMax 
	personaje.actualizar_barra()
	personaje.partes = partes
	return personaje

func crearPartePersonaje(skills: Array[Skill]) -> PartePersonaje:
	var partePersonaje: PartePersonaje = ESCENA_PARTE_PERSONAJE.instantiate()
	partePersonaje.skills = skills
	return partePersonaje


func crearSkill(nombre: String, dmg: int, sta: int) -> Skill:
	var skill: Skill = ESCENA_SKILL.instantiate()
	skill.nombreSkill= nombre
	skill.dmgSkill = dmg
	skill.staSkill = sta
	contenedor.add_child(skill)
	return skill

func _on_carta_soltada(skill: Skill, parte: ParteEnemigo) -> void:
	if combate_terminado or not skill.disponible or skill.usada:
		return
	parteEnemigaSeleccionada = parte
	skill.marcarUsada()
	_onSkillElegida(skill.dmgSkill, skill.staSkill)

func _onSkillElegida(dmg: int, sta: int) -> void:
	if combate_terminado:
		return

	parteEnemigaSeleccionada.sufrirDmg(dmg)
	enemigo_actual.actualizar_barra()
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
	personaje.staminaActual = personaje.staminaMax
	personaje.actualizar_barra()
	for hijo in contenedor.get_children():
		if hijo is Skill:
			hijo.recuperar()
	updateSkills()

func updateSkills() -> void:
	for hijo in contenedor.get_children():
		if hijo is Skill:
			hijo.updateDisponibilidad(personaje.staminaActual)

func ganarCombate() -> void:
	combate_terminado = true
	EstadoPartida.enemigo_derrotado = true
	EstadoPartida.volver_de_combate = true
	get_tree().change_scene_to_file(
		"res://escenas/Exploración/Pisos/PlantaCero.tscn"
	)

func _on_button_pressed() -> void:
	pass # Replace with function body.
