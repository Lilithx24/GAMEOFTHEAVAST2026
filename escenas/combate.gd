extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")

@onready var enemigo = $Enemigo
@onready var contenedor = $PanelJugador/HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemigo = $Enemigo
	contenedor = $PanelJugador/HBoxContainer
	crearSkill("Ataque 15 de daño", 15)
	crearSkill("Ataque 10 de daño", 10)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func crearSkill(nombre: String, dmg: int) -> void:
	var skill: Skill = ESCENA_SKILL.instantiate()
	skill.nombreSkill= nombre
	skill.dmgSkill = dmg
	skill.skillUsada.connect(_onSkillElegida)
	contenedor.add_child(skill)

func _onSkillElegida(dmg: int) -> void:
	enemigo.sufrir_damage(dmg)

func _on_button_pressed() -> void:
	pass # Replace with function body.
