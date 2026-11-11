extends Slot

@onready var etiqueta_nombre: Label = $Contenido/Textos/Nombre
@onready var etiqueta_habilidad: Label = $Contenido/Textos/DescripcionHabilidad


func poner_item(nuevo: ParteInventario) -> void:
	super.poner_item(nuevo)
	etiqueta_nombre.text = nuevo.nombre if nuevo != null else ""
	etiqueta_habilidad.text = nuevo.descripcion_habilidad if nuevo != null else ""
