class_name Combate
extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")
const ESCENA_ENEMIGO := preload("res://escenas/assetsCombate/enemigo.tscn")
const ESCENA_PARTE_ENEMIGO := preload("res://escenas/assetsCombate/assetsEnemigo/parteEnemigo.tscn")
const ESCENA_PERSONAJE := preload("res://escenas/assetsCombate/personaje/personaje.tscn")


var parteEnemigaSeleccionada: ParteEnemigo
var enemigo_actual: Enemigo
var personaje: Personaje
var combate_terminado: bool = false
@onready var contenedor = $PanelJugador/HBoxContainer
var stamina: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contenedor = $PanelJugador/HBoxContainer
	crearSkill("Ataque 15 de daño", 15, 2)
	crearSkill("Ataque 10 de daño", 10, 1)
	crearEnemigo(100)
	crearPersonaje()
	stamina = 2

func crearEnemigo(vida: int) -> void:
	enemigo_actual = ESCENA_ENEMIGO.instantiate()
	add_child(enemigo_actual)
	crearParte(enemigo_actual, vida)
	enemigo_actual.actualizar_barra()

func crearParte(enemigo:Enemigo, vida: int) -> void:
	var parte: ParteEnemigo = ESCENA_PARTE_ENEMIGO.instantiate()
	parte.vidaMax = vida
	parte.vidaActual = parte.vidaMax
	parte.vital = true
	parteEnemigaSeleccionada = parte
	enemigo.parte = parte
	enemigo.add_child(parte)

func crearSkill(nombre: String, dmg: int, sta: int) -> void:
	var skill: Skill = ESCENA_SKILL.instantiate()
	skill.nombreSkill= nombre
	skill.dmgSkill = dmg
	skill.staSkill = sta
	skill.skillUsada.connect(_onSkillElegida)
	contenedor.add_child(skill)
	
func crearPersonaje() -> void:
	personaje = ESCENA_PERSONAJE.instantiate()
	personaje.vidaActual = personaje.vidaMax
	add_child(personaje)
	personaje.actualizar_barra()

func _onSkillElegida(dmg: int, sta: int) -> void:
	if combate_terminado:
		return

	parteEnemigaSeleccionada.sufrirDmg(dmg)
	enemigo_actual.actualizar_barra()
	stamina = stamina - sta
	if stamina < 1:
		print("recibes daño")
		personaje.sufrirDmg(10)
		stamina = 2
		personaje.actualizar_barra()
	if parteEnemigaSeleccionada.vidaActual == 0 \
			and parteEnemigaSeleccionada.vital:
		ganar_combate()

func ganar_combate() -> void:
	combate_terminado = true
	EstadoPartida.enemigo_derrotado = true
	EstadoPartida.volver_de_combate = true
	get_tree().change_scene_to_file(
		"res://escenas/Exploración/Pisos/PlantaCero.tscn"
	)

func _on_button_pressed() -> void:
	pass # Replace with function body.
