class_name Combate
extends Node2D

const ESCENA_SKILL := preload("res://escenas/assetsCombate/skill.tscn")
const ESCENA_PERSONAJE := preload("res://escenas/assetsCombate/personaje.tscn")
const ESCENA_PARTE_PERSONAJE := preload("res://escenas/assetsCombate/assetsPersonaje/partePersonaje.tscn")
const ESCENA_MUERTE := preload("res://escenas/PantallaMuerte/pantallaMuerte.tscn")

var parteEnemigaSeleccionada: ParteEnemigo
@onready var enemigo_actual: Enemigo = $Enemigo
var personaje: Personaje
var combate_terminado: bool = false
var partes_usadas: Dictionary = {}
var skillSolicitada: bool = false
@onready var barra_vida: ProgressBar = $PanelJugador/CanvasLayer/Interfaz/Stadisticas/ProgressBarJ
@onready var contenedor = $PanelJugador/ScrollContainer/HBoxContainer
@onready var contador_stamina: Control = $PanelJugador/CanvasLayer/Interfaz/ContadorStamina
@onready var texto_stats: Label = $PanelJugador/CanvasLayer/Interfaz/Stadisticas/TextoStats

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contenedor = $PanelJugador/ScrollContainer/HBoxContainer
	enemigo_actual.configurar_apariencia(EstadoPartida.tipo_enemigo_actual)
	for parte in enemigo_actual.partes:
		parte.carta_soltada.connect(_on_carta_soltada)
	personaje = crearPersonaje(EstadoPartida.obtener_vida_maxima(), [])
	aplicarEstadísticas()
	EstadoPartida.inventario_cambiado.connect(_solicitar_skills)
	reconstruirSkills()
	personaje.staminaActual = personaje.stamina
	updateSkills()
	personaje.murio.connect(_on_personaje_murio)
	actualizar_barraJ()


func _solicitar_skills() -> void:
	skillSolicitada = true
	aplicarEstadísticas()
	
	
func aplicarEstadísticas() -> void:
	var cabeza: ParteInventario = EstadoPartida.equipo["cabeza"]
	var piernas: ParteInventario = EstadoPartida.equipo["piernas"]
	var torso: ParteInventario = EstadoPartida.equipo["torso"]

	###### aplicar los bufos a las estadísticas de los items ######
	personaje.stamina = personaje.staminaBase + stat(cabeza, "stamina") + stat(piernas, "stamina")
	personaje.evasion =  stat(cabeza, "evasion") + stat(piernas, "evasion")
	personaje.proteccion = stat(cabeza, "proteccion") + stat(piernas, "proteccion") + stat(torso, "proteccion")
	personaje.modDmg = stat(cabeza, "modDmg") + stat(piernas, "modDmg")
	
	###### Cambiamos el texto de la interfaz acorde a los cambios realizados ######
	texto_stats.text = "Vida: \nProtección: %d\nEvasión: %d\nDaño extra: %d" % [
		personaje.proteccion,
		personaje.evasion,
		personaje.modDmg
	]


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



	updateSkills()
	
	
###### Funciones de instanciamiento ######

func crearPersonaje(vida: int,partes: Array[PartePersonaje]) -> Personaje:
	var personaje: Personaje = ESCENA_PERSONAJE.instantiate()
	add_child(personaje)
	personaje.vidaMax = vida
	personaje.vidaActual = personaje.vidaMax
	personaje.actualizar_barra()
	personaje.partes = partes
	return personaje


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
	await _onSkillElegida(skill.dmgSkill + personaje.modDmg, skill.staSkill, skill.efectos)
	if not combate_terminado and is_instance_valid(skill) and skill.parte_origen and skill.parte_origen.renueva_carta_al_usar:
		_reemplazar_carta_usada(skill)


func _reemplazar_carta_usada(skill: Skill) -> void:
	if skill.get_parent() != contenedor or not EstadoPartida.brazos_equipados.has(skill.parte_origen):
		return
	var posicion := skill.get_index()
	partes_usadas.erase(skill.parte_origen)
	contenedor.remove_child(skill)
	var nueva := crearSkill(skill.nombreSkill, skill.dmgSkill, skill.staSkill, skill.parte_origen, skill.efectos)
	contenedor.move_child(nueva, posicion)
	nueva.updateDisponibilidad(personaje.staminaActual)
	skill.queue_free()

func _onSkillElegida(dmg: int, sta: int, efectos: Array[String]) -> void:
	if combate_terminado:
		return
	personaje.staminaActual -= sta
	personaje.actualizar_barra()
	actualizar_barraJ()
	if "sanacion" in efectos:
		personaje.vidaActual = personaje.vidaActual + dmg
		personaje.actualizar_barra()
		actualizar_barraJ()
	else:
		parteEnemigaSeleccionada.sufrirDmg(dmg*(1 - 0.25 * personaje.debilEstado))
		enemigo_actual.actualizar_barra()
	if "multihit2" in efectos:
		await get_tree().create_timer(0.1).timeout
		parteEnemigaSeleccionada.sufrirDmg(dmg*(1 - 0.25 * personaje.debilEstado))
		enemigo_actual.actualizar_barra()
	if "multihit3" in efectos:
		await get_tree().create_timer(0.1).timeout
		parteEnemigaSeleccionada.sufrirDmg(dmg*(1 - 0.25 * personaje.debilEstado))
		enemigo_actual.actualizar_barra()
		await get_tree().create_timer(0.1).timeout
		parteEnemigaSeleccionada.sufrirDmg(dmg*(1 - 0.25 * personaje.debilEstado))
		enemigo_actual.actualizar_barra()
	if "debil" in efectos:
		enemigo_actual.debilContador = enemigo_actual.debilContador + 1
	if "stun" in efectos:
		enemigo_actual.stun = enemigo_actual.stun + 1
	if "atrapar" in efectos:
		if not parteEnemigaSeleccionada.datos.estados.has("atrapado"):
			parteEnemigaSeleccionada.datos.estados.append("atrapado")
	if parteEnemigaSeleccionada.vidaActual == 0 \
			and parteEnemigaSeleccionada.datos.vital:
		ganarCombate()
		return
	updateSkills()

func actualizar_barraJ() -> void:
	barra_vida.max_value = personaje.vidaMax
	barra_vida.value = personaje.vidaActual

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		terminarTurno()

func terminarTurno() -> void:
	############# Esto checkea los brazos que se han quedado sin usos para eliminarlos
	for i in EstadoPartida.brazos_equipados.size():
		var brazo := EstadoPartida.brazos_equipados[i] as BrazoInventario
		if brazo != null and brazo.usos_actuales() <= 0:
			EstadoPartida.brazos_equipados[i] = null
	_retirar_cartas_huerfanas()
	####################################
	if combate_terminado:
		return
	enemigo_actual.turno(personaje)
	partes_usadas.clear()
	personaje.actualizar_barra()
	actualizar_barraJ()
	for hijo in contenedor.get_children():
		if hijo is Skill:
			hijo.recuperar()
	if skillSolicitada == true:
		reconstruirSkills()
		skillSolicitada = false

	personaje.staminaActual = personaje.stamina - personaje.stun #recargamos la estamina quitandole estamina al personaje por cada contador de stun
	personaje.stun = 0 #reseteamos el contador de stuns del personaje
	if personaje.debilContador > 0: #actualizamos los turnos de débil
		personaje.debilEstado = 1
		personaje.debilContador = personaje.debilContador - 1
	else:
		personaje.debilEstado = 0
	
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
	
func _retirar_cartas_huerfanas() -> void:
	for hijo in contenedor.get_children():
		var carta := hijo as Skill
		if carta == null or carta.parte_origen == null:
			continue
		if not EstadoPartida.brazos_equipados.has(carta.parte_origen):
			contenedor.remove_child(carta)
			carta.queue_free()

func ganarCombate() -> void:
	combate_terminado = true
	if not EstadoPartida.enemigo_actual_id.is_empty():
		EstadoPartida.enemigos_derrotados[EstadoPartida.enemigo_actual_id] = true
	EstadoPartida.enemigo_actual_id = ""
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
