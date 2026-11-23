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
	var posicion_guardada: Transform3D = jugador.global_transform
	var puerta = nivel.get_node("PisoCero/Puertas/ParedConPuerta")
	puerta.duracion_apertura = 0.01
	await puerta.interactuar()
	nivel._on_punto_alcanzado(nivel.punto_combate)
	verificar(transicion.en_curso and paused and transicion.visible, "El encuentro inicia la transición y bloquea el juego")
	verificar(not transicion._luces.is_empty(), "Se controlan las luces reales del nivel")
	verificar(transicion.sfx_apagon.stream != null and transicion.sfx_encendido.stream != null, "Los dos SFX están asignados en la escena")
	var menu = nivel.get_node("MenuShift")
	menu.abrir()
	verificar(not menu.visible, "SHIFT no puede abrirse durante la transición")
	nivel._on_punto_alcanzado(nivel.punto_combate)
	verificar(estado.transform_jugador.is_equal_approx(posicion_guardada), "Se conserva la posición sin duplicar el encuentro")
	await create_timer(0.3).timeout
	var indice: int = transicion._energias.find(transicion._energias.max())
	verificar(transicion._luces[indice].light_energy < transicion._energias[indice], "Las luces pierden energía durante el apagón")
	verificar(jugador.get_node("Camera3D").fov < 75.0, "La cámara se acerca durante el apagón")
	await scene_changed
	verificar(current_scene.scene_file_path == transicion.escena_combate, "El apagón cambia a la escena de combate")
	verificar(is_equal_approx(transicion.negro.color.a, 1.0) and paused, "El cambio de escena ocurre completamente a oscuras y con el juego bloqueado")
	await transicion.finalizada
	verificar(not transicion.en_curso and not transicion.visible and not paused, "El encendido devuelve el control y retira los efectos")
	verificar(transicion._luces.is_empty() and transicion._emisivos.is_empty(), "No quedan referencias al piso anterior")
	current_scene.ganarCombate()
	await scene_changed
	verificar(current_scene.get_node("PisoCero/Puertas/ParedConPuerta").abierta, "Las puertas siguen abiertas al volver del combate")
	verificar(current_scene.get_node("PisoCero/Jugador").global_transform.is_equal_approx(posicion_guardada), "La vuelta conserva la posición original, sin el movimiento de cámara")
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
