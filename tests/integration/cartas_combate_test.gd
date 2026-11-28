extends SceneTree

var fallos := 0

func verificar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)
	else:
		print("OK: ", mensaje)

func _initialize() -> void:
	probar.call_deferred()

func probar() -> void:
	var estado := root.get_node("EstadoPartida")
	var brazo := load("res://Recursos/partes/brazo_humano.tres").duplicate() as BrazoInventario
	var otro := load("res://Recursos/partes/brazo_cangrejo.tres").duplicate() as BrazoInventario
	# Fijar el coste de esta prueba sin depender del balance del recurso.
	otro.staSkill = 1
	estado.brazos_equipados.assign([brazo, otro])
	var combate = load("res://escenas/Combate.tscn").instantiate()
	root.add_child(combate)
	await process_frame
	verificar(combate.contenedor.get_child_count() == 2, "Una carta por brazo equipado")
	var carta := combate.contenedor.get_child(0) as Skill
	verificar(carta.parte_origen == brazo and carta.dmgSkill == brazo.dmgSkill, "La carta conserva el ataque de su parte")
	verificar(carta.get_node("VBoxContainer/Damage").text == "10 damage", "La carta muestra el daño")
	var objetivo = combate.enemigo_actual.partes[0]
	combate._on_carta_soltada(carta, objetivo)
	verificar(objetivo.vidaActual == 90 and combate.personaje.staminaActual == 1, "Jugar carta aplica daño y coste")
	combate._on_carta_soltada(carta, objetivo)
	verificar(objetivo.vidaActual == 90, "Una carta usada no puede repetirse")
	estado.brazos_equipados.assign([otro])
	combate.reconstruirSkills()
	verificar(combate.contenedor.get_child_count() == 1, "Desequipar retira la carta")
	estado.brazos_equipados.assign([brazo, otro])
	combate.reconstruirSkills()
	carta = combate.contenedor.get_child(0) as Skill
	verificar(carta.usada, "Reequipar no recupera la carta usada")
	combate._on_carta_soltada(combate.contenedor.get_child(1), objetivo)
	verificar(combate.personaje.staminaActual == 0, "Dos ataques consumen la stamina")
	combate.terminarTurno()
	verificar(not carta.usada and carta.disponible and combate.personaje.staminaActual == 2, "Terminar turno recupera cartas y stamina")
	combate.personaje.staminaActual = 0
	combate.updateSkills()
	combate._on_carta_soltada(carta, objetivo)
	verificar(objetivo.vidaActual == 75 and not carta.disponible, "Sin stamina no se puede atacar")
	var ak47 := load("res://Recursos/partes/brazo_ak47.tres").duplicate() as BrazoInventario
	estado.brazos_equipados.assign([otro, ak47])
	combate.personaje.staminaActual = 2
	combate.reconstruirSkills()
	var anterior := combate.contenedor.get_child(1) as Skill
	combate._on_carta_soltada(anterior, objetivo)
	var nueva := combate.contenedor.get_child(1) as Skill
	verificar(objetivo.vidaActual == 73 and combate.personaje.staminaActual == 1, "AK47 hace 2 de daño y consume 1 de stamina")
	verificar(nueva != anterior and anterior.usada and anterior.get_parent() == null, "La carta usada se consume y se reemplaza por otra instancia")
	verificar(combate.contenedor.get_child_count() == 2 and nueva.parte_origen == ak47 and not nueva.usada and nueva.disponible, "La nueva carta conserva origen y posición sin duplicar la mano")
	combate._on_carta_soltada(anterior, objetivo)
	verificar(objetivo.vidaActual == 73, "La instancia antigua no puede volver a atacar")
	combate._on_carta_soltada(nueva, objetivo)
	verificar(objetivo.vidaActual == 71 and combate.personaje.staminaActual == 0, "El AK47 se puede usar de nuevo en el mismo turno")
	carta = combate.contenedor.get_child(1) as Skill
	verificar(not carta.usada and not carta.disponible, "La carta se renueva incluso sin stamina, pero queda bloqueada por su coste")
	combate._on_carta_soltada(carta, objetivo)
	verificar(objetivo.vidaActual == 71, "Renovar no permite atacar sin stamina")
	combate.reconstruirSkills()
	carta = combate.contenedor.get_child(1) as Skill
	verificar(not carta.usada and not combate.partes_usadas.has(ak47), "Reconstruir el equipo conserva la carta renovada")
	combate.queue_free()
	await process_frame
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
