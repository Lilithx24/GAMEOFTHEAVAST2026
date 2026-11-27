extends CanvasLayer

@onready var copia: BackBufferCopy = $CopiaPantalla
@onready var efecto: ColorRect = $Efecto


func _ready() -> void:
	EstadoPartida.inventario_cambiado.connect(_actualizar_vision)
	_actualizar_vision()


func _actualizar_vision() -> void:
	var cabeza := EstadoPartida.equipo.get("cabeza") as CabezaInventario
	var material_vision: ShaderMaterial = cabeza.vision_material if cabeza != null else null
	efecto.material = material_vision
	efecto.visible = material_vision != null
	# Copiar después del acabado retro y antes de la interfaz.
	copia.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if material_vision != null else BackBufferCopy.COPY_MODE_DISABLED
