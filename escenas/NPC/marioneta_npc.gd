extends Node2D

func aceptar() -> void:
	$AnimationPlayer.play("aceptar", 0.15)
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("idle", 0.15)
