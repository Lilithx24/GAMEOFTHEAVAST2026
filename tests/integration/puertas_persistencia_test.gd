extends SceneTree

const NIVEL := "res://escenas/Exploración/Pisos/PlantaCero.tscn"
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
	change_scene_to_file(NIVEL)
	await scene_changed
	var primera = current_scene.get_node("PisoCero/Puertas/ParedConPuerta")
	var segunda = current_scene.get_node("PisoCero/Puertas/ParedConPuerta2")
	primera.duracion = 0.01
	segunda.duracion = 0.01
	await primera.interactuar()
	await segunda.interactuar()
	await segunda.interactuar()
	verificar(primera.abierta and not segunda.abierta, "Una puerta abierta y otra cerrada antes del combate")

	change_scene_to_file("res://escenas/Combate.tscn")
	await scene_changed
	current_scene.ganarCombate()
	await scene_changed
	primera = current_scene.get_node("PisoCero/Puertas/ParedConPuerta")
	segunda = current_scene.get_node("PisoCero/Puertas/ParedConPuerta2")
	verificar(primera.abierta, "La puerta abierta se conserva al ganar el combate")
	verificar(not segunda.abierta, "La puerta que se volvió a cerrar sigue cerrada")
	verificar(is_equal_approx(primera.bisagra.rotation.y, primera.giro_cerrado + deg_to_rad(primera.angulo_apertura)), "La hoja y su colisión recuperan la rotación abierta")
	verificar(not primera.animando and not primera.sonido_apertura.playing, "Restaurar no reproduce animación ni sonido")
	primera.duracion = 0.01
	await primera.interactuar()
	verificar(not primera.abierta and is_equal_approx(primera.bisagra.rotation.y, primera.giro_cerrado), "La puerta restaurada puede cerrarse normalmente")
	await primera.interactuar()

	root.get_node("EstadoPartida").reiniciarNivel()
	await scene_changed
	primera = current_scene.get_node("PisoCero/Puertas/ParedConPuerta")
	verificar(not primera.abierta, "Reiniciar el nivel restablece las puertas")
	verificar(root.get_node("EstadoPartida").estados_puertas.is_empty(), "Reiniciar limpia los estados guardados")
	print("RESULTADO: ", fallos, " fallos")
	quit(fallos)
