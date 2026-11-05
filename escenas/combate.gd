class_name Combate
extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")
const ESCENA_ENEMIGO := preload("res://escenas/assetsCombate/enemigo.tscn")
const ESCENA_PARTE_ENEMIGO := preload("res://escenas/assetsCombate/assetsEnemigo/parteEnemigo.tscn")

var parteEnemigaSeleccionada: ParteEnemigo
@onready var contenedor = $PanelJugador/HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contenedor = $PanelJugador/HBoxContainer
	crearSkill("Ataque 15 de daño", 15)
	crearSkill("Ataque 10 de daño", 10)
	crearEnemigo(100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func crearEnemigo(vida: int) -> void:
	var enemigo: Enemigo = ESCENA_ENEMIGO.instantiate()
	self.add_child(enemigo)
	crearParte(enemigo, vida)

func crearParte(enemigo:Enemigo, vida: int) -> void:
	var parte: ParteEnemigo = ESCENA_PARTE_ENEMIGO.instantiate()
	parte.vidaMax = vida
	parte.vidaActual = parte.vidaMax
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
	parteEnemigaSeleccionada.sufrirDmg(dmg)

func _on_button_pressed() -> void:
	pass # Replace with function body.
