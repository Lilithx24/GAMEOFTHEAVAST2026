extends Node2D
var enemigo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var enemigo = $Enemigo

func _on_ataque1_pressed ():
	enemigo.sufrir_damage(15)
	
func _ataque2_pressed ():
	enemigo.sufrir_damage(10)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	pass # Replace with function body.
