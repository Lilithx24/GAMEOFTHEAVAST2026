extends SceneTree
var fallos := 0
func verificar(valor: bool, mensaje: String) -> void:
	if valor:
		print("OK: ", mensaje)
	else:
		fallos += 1
		push_error(mensaje)
func _initialize() -> void:
	call_deferred("probar")
func probar() -> void:
	var estado = root.get_node("EstadoPartida")
	var cerveza = load("res://Recursos/partes/brazo_cerveza.tres").duplicate()
	estado.brazos_equipados.assign([cerveza])
	var combate = load("res://escenas/Combate.tscn").instantiate()
	root.add_child(combate)
	await process_frame
	var jugador = combate.personaje
	jugador.staminaActual = 99
	jugador.setVidaActual(jugador.vidaMax - 1)
	combate.updateSkills()
	var carta = combate.contenedor.get_child(0)
	await combate._on_carta_soltada(carta, combate.enemigo_actual.partes[0])
	verificar(jugador.vidaActual == jugador.vidaMax, "La cerveza no supera la vida máxima")
	verificar(combate.barra_vida.value == jugador.vidaMax, "La barra muestra la vida limitada")
	jugador.setVidaActual(jugador.vidaMax + 100)
	verificar(jugador.vidaActual == jugador.vidaMax, "El setter limita cualquier curación excesiva")
	var aviso = combate.get_node("PanelJugador/CanvasLayer/AvisoEsquiva")
	verificar(not aviso.visible, "Dodged está oculto inicialmente")
	jugador.evasion = 100
	for tipo in [0, 1]:
		combate.enemigo_actual.configurar_apariencia(tipo)
		var animacion = combate.enemigo_actual.get_node("Objetivo/Enemigo%d/AnimationPlayer" % (tipo + 1))
		var cuerpo = combate.enemigo_actual.get_node("Objetivo/Enemigo%d/Cadera" % (tipo + 1))
		var reposo: Vector2 = cuerpo.position
		combate.terminarTurno()
		verificar(combate.turno_enemigo and animacion.is_playing(), "El enemigo %d inicia su animación" % tipo)
		combate.terminarTurno()
		await create_timer(0.07).timeout
		verificar(not cuerpo.position.is_equal_approx(reposo), "La animación mueve el cuerpo")
		await create_timer(0.09).timeout
		verificar(aviso.visible and aviso.get_node("Texto").text == "Dodged", "La evasión muestra Dodged")
		verificar(jugador.vidaActual == jugador.vidaMax, "Esquivar conserva la vida")
		while combate.turno_enemigo:
			await process_frame
		verificar(cuerpo.position.is_equal_approx(reposo), "El enemigo vuelve a su posición")
		verificar(not animacion.is_playing(), "No se encadenan ataques al repetir E")
		await create_timer(0.9).timeout
		verificar(not aviso.visible, "Dodged desaparece automáticamente")
	jugador.evasion = 0
	jugador.proteccion = 0
	jugador.sufrirDmg(1)
	verificar(jugador.vidaActual == jugador.vidaMax - 1 and not aviso.visible, "Un impacto resta vida sin mostrar Dodged")
	combate.enemigo_actual.stun = 1
	await combate.terminarTurno()
	verificar(not combate.turno_enemigo and jugador.vidaActual == jugador.vidaMax - 1, "El enemigo aturdido no ataca")
	combate.queue_free()
	await process_frame
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
