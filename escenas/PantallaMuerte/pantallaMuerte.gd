extends CanvasLayer

signal reiniciarNivel

@onready var boton: Button = $CenterContainer/VBoxContainer/BotonReiniciar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona con el juego pausado
	boton.pressed.connect(_on_reiniciar)


func _on_reiniciar() -> void:
	reiniciarNivel.emit()
