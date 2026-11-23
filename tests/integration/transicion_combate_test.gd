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
	# Evita que un fallo en una señal deje la prueba esperando indefinidamente.
	create_timer(15.0).timeout.connect(func(): quit(1))
	change_scene_to_file("res://escenas/Exploración/Pisos/PlantaCero.tscn")
	await scene_changed
	var nivel = current_scene
	var transicion = root.get_node("TransicionCombate")
	var estado = root.get_node("EstadoPartida")
	var jugador = nivel.get_node("PisoCero/Jugador")
	jugador.set_physics_process(false)
	jugador.global_position = Vector3(0, 1.2, -20)
	jugador.rotation.y = -PI / 2.0
	var posicion_guardada: Transform3D = jugador.global_transform
	var fov_original: float = jugador.get_node("Camera3D").fov
	var enemigo = nivel.get_node("PisoCero/EnemigoExploracion")
	# Posición controlada para comprobar la oclusión, independiente del diseño del mapa.
	enemigo.global_position = Vector3(11.14, 0, -20)
	var distancia_inicial: float = enemigo.global_position.distance_to(jugador.global_position)
	var puerta = nivel.get_node("PisoCero/Puertas/Puerta_C_D")
	await physics_frame
	await physics_frame
	jugador._detectar_enemigo()
	verificar(not transicion.en_curso, "La puerta cerrada bloquea la detección del enemigo")
	verificar(jugador.rayo_enemigos.get_collider() == puerta.get_node("Bisagra/Puerta/Cuerpo"), "El raycast detecta la hoja cerrada como obstáculo")
	puerta.duracion_apertura = 0.01
	await puerta.interactuar()
	await physics_frame
	jugador.rotation.y = PI / 2.0
	jugador._detectar_enemigo()
	verificar(not transicion.en_curso, "Mirar en dirección contraria no inicia combate")
	jugador.rotation.y = -PI / 2.0
	await physics_frame
	jugador._detectar_enemigo()
	verificar(transicion.en_curso and paused and transicion.visible, "El encuentro inicia la transición y bloquea el juego")
	verificar(not transicion._luces.is_empty(), "Se controlan las luces reales del nivel")
	verificar(transicion.sfx_apagon.stream != null and transicion.sfx_encendido.stream != null, "Los dos SFX están asignados en la escena")
	var menu = nivel.get_node("MenuShift")
	menu.abrir()
	verificar(not menu.visible, "SHIFT no puede abrirse durante la transición")
	nivel._on_enemigo_detectado(enemigo)
	verificar(estado.transform_jugador.is_equal_approx(posicion_guardada), "Se conserva la posición sin duplicar el encuentro")
	await create_timer(0.25).timeout
	verificar(enemigo.global_position.distance_to(jugador.global_position) < distancia_inicial, "El enemigo se abalanza mientras el jugador permanece quieto")
	verificar(not is_zero_approx(enemigo.get_node("MarionetaViewport/Enemigo1/Cadera/Torso/BrazoCangrejo").rotation), "La pinza se anima durante la embestida")
	verificar(jugador.global_transform.is_equal_approx(posicion_guardada), "No hace falta avanzar para entrar en combate")
	await create_timer(0.55).timeout
	var indice: int = transicion._energias.find(transicion._energias.max())
	verificar(transicion._luces[indice].light_energy < transicion._energias[indice], "Las luces pierden energía durante el apagón")
	verificar(jugador.get_node("Camera3D").fov < fov_original, "La cámara se acerca durante el apagón")
	await scene_changed
	verificar(current_scene.scene_file_path == transicion.escena_combate, "El apagón cambia a la escena de combate")
	verificar(current_scene.get_node("Enemigo/Objetivo/Enemigo1").visible and not current_scene.get_node("Enemigo/Objetivo/Enemigo2").visible, "El primer encuentro muestra al enemigo 1 en combate")
	verificar(is_equal_approx(transicion.negro.color.a, 1.0) and paused, "El cambio de escena ocurre completamente a oscuras y con el juego bloqueado")
	await transicion.finalizada
	verificar(not transicion.en_curso and not transicion.visible and not paused, "El encendido devuelve el control y retira los efectos")
	verificar(transicion._luces.is_empty() and transicion._emisivos.is_empty(), "No quedan referencias al piso anterior")
	current_scene.ganarCombate()
	await scene_changed
	verificar(current_scene.get_node("PisoCero/Puertas/Puerta_C_D").abierta, "Las puertas siguen abiertas al volver del combate")
	verificar(current_scene.get_node("PisoCero/Jugador").global_transform.is_equal_approx(posicion_guardada), "La vuelta conserva la posición original, sin el movimiento de cámara")
	await process_frame
	verificar(current_scene.get_node_or_null("PisoCero/EnemigoExploracion") == null and not transicion.en_curso, "El enemigo derrotado no vuelve a iniciar otro encuentro")
	var segundo = current_scene.get_node_or_null("PisoCero/EnemigoExploracion2")
	verificar(segundo != null and not segundo.activado, "Derrotar al primero conserva al segundo enemigo")
	segundo.global_position = Vector3(30, 0, -33)
	jugador = current_scene.get_node("PisoCero/Jugador")
	jugador.set_physics_process(false)
	jugador.global_position = Vector3(30, 1.2, -30)
	jugador.rotation = Vector3.ZERO
	await physics_frame
	await physics_frame
	jugador._detectar_enemigo()
	verificar(transicion.en_curso and estado.enemigo_actual_id == segundo.id_enemigo, "El raycast inicia el segundo encuentro de forma independiente")
	await create_timer(0.25).timeout
	verificar(not is_zero_approx(segundo.get_node("MarionetaViewport/Enemigo2/Cadera/Torso/BrazoAla").rotation), "El ala se anima durante la segunda embestida")
	await transicion.finalizada
	verificar(current_scene.get_node("Enemigo/Objetivo/Enemigo2").visible and not current_scene.get_node("Enemigo/Objetivo/Enemigo1").visible, "El segundo encuentro muestra al enemigo 2 en combate")
	current_scene.ganarCombate()
	await scene_changed
	await process_frame
	verificar(estado.enemigos_derrotados.size() == 2 and get_nodes_in_group("enemigos_exploracion").is_empty(), "Ambos enemigos permanecen derrotados")
	estado.reiniciarNivel()
	await scene_changed
	verificar(estado.enemigos_derrotados.is_empty() and get_nodes_in_group("enemigos_exploracion").size() == 2, "Reiniciar el nivel restaura ambos enemigos")
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
