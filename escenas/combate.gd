class_name Combate
extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")
const ESCENA_ENEMIGO := preload("res://escenas/assetsCombate/enemigo.tscn")
const ESCENA_PARTE_ENEMIGO := preload("res://escenas/assetsCombate/assetsEnemigo/parteEnemigo.tscn")

var parteEnemigaSeleccionada: ParteEnemigo
var enemigo_actual: Enemigo
var combate_terminado: bool = false
@onready var contenedor = $PanelJugador/HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contenedor = $PanelJugador/HBoxContainer
	crearSkill("Ataque 15 de daño", 15)
	crearSkill("Ataque 10 de daño", 10)
	crearEnemigo(100)

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

func crearSkill(nombre: String, dmg: int) -> void:
	var skill: Skill = ESCENA_SKILL.instantiate()
	skill.nombreSkill= nombre
	skill.dmgSkill = dmg
	skill.skillUsada.connect(_onSkillElegida)
	contenedor.add_child(skill)

func _onSkillElegida(dmg: int) -> void:
	if combate_terminado:
		return

	parteEnemigaSeleccionada.sufrirDmg(dmg)
	enemigo_actual.actualizar_barra()

	if parteEnemigaSeleccionada.vidaActual == 0 \
			and parteEnemigaSeleccionada.vital:
		ganar_combate()

func ganar_combate() -> void:
	combate_terminado = true
	EstadoPartida.enemigo_derrotado = true
	EstadoPartida.volver_de_combate = true
	get_tree().change_scene_to_file(
		"res://escenas/Exploración/exploracion.tscn"
	)

func _on_button_pressed() -> void:
	pass # Replace with function body.
