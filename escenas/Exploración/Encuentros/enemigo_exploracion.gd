extends Area3D

@export var id_enemigo: String = ""
@export_enum("Enemigo 1", "Enemigo 2") var tipo_enemigo: int = 0
@export_range(0.1, 2.0, 0.05) var duracion_embestida: float = 0.45
@export_range(0.3, 3.0, 0.05) var distancia_final: float = 1.2
@export_range(0.0, 0.5, 0.01) var altura_salto: float = 0.15

var activado: bool = false


func identificador() -> String:
	return id_enemigo if not id_enemigo.is_empty() else str(get_path())


func abalanzarse(camara: Camera3D) -> void:
	if activado:
		return
	activado = true
	var marioneta := $MarionetaViewport.get_child(0)
	var animacion := marioneta.get_node("AnimationPlayer") as AnimationPlayer
	animacion.play("asalto", -1, animacion.get_animation("asalto").length / duracion_embestida)
	var hacia_jugador := camara.global_position - global_position
	hacia_jugador.y = 0.0
	var distancia := hacia_jugador.length()
	var destino := global_position + hacia_jugador.normalized() * maxf(0.0, distancia - distancia_final)
	var altura_original: float = $Imagen.position.y
	# El encuentro pausa el mundo; estos tweens completan la embestida bajo esa pausa.
	var avance := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	avance.tween_property(self, "global_position", destino, duracion_embestida).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var salto := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	salto.tween_property($Imagen, "position:y", altura_original + altura_salto, duracion_embestida * 0.4).set_trans(Tween.TRANS_SINE)
	salto.tween_property($Imagen, "position:y", altura_original, duracion_embestida * 0.6).set_trans(Tween.TRANS_SINE)
	await avance.finished
