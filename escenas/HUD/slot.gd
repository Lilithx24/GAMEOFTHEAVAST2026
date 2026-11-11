class_name Slot
extends PanelContainer

signal item_cambiado(slot: Slot)

@export var tag_requerido: String = ""   # "" = acepta cualquier parte
@export var permite_arrastrar: bool = true
@export_enum("inventario", "temporal", "cabeza", "torso", "piernas", "brazo") var zona: String = "inventario"
@export var indice: int = 0

@onready var icono: TextureRect = $Icono

var item: ParteInventario
var validar_entrega: Callable
var entregar: Callable
static var iconos_ajustados: Dictionary = {}

func poner_item(nuevo: ParteInventario) -> void:
	item = nuevo
	icono.texture = _ajustar_textura(nuevo.textura) if nuevo else null
	item_cambiado.emit(self)


func _ajustar_textura(textura: Texture2D) -> Texture2D:
	if textura == null:
		return null
	if iconos_ajustados.has(textura):
		return iconos_ajustados[textura]
	# Los recortes originales contienen margen transparente. El slot encuadra
	# solo la pieza sin modificar el archivo ni las proporciones de su imagen.
	var imagen := textura.get_image()
	if imagen == null:
		return textura
	if imagen.is_compressed():
		if imagen.decompress() != OK:
			return textura
	var region := imagen.get_used_rect()
	if not region.has_area():
		return textura
	var atlas := AtlasTexture.new()
	atlas.atlas = textura
	atlas.region = Rect2(region)
	atlas.filter_clip = true
	iconos_ajustados[textura] = atlas
	return atlas

func acepta(candidato: ParteInventario) -> bool:
	if candidato == null:
		return true
	return tag_requerido == "" or candidato.tags.has(tag_requerido)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not permite_arrastrar:
		return null
	if item == null:
		return null
	var preview := TextureRect.new()
	preview.texture = icono.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)
	return self

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Slot or data == self:
		return false
	var origen: Slot = data
	if validar_entrega.is_valid():
		return validar_entrega.call(origen, self)
	return acepta(origen.item) and origen.acepta(item)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var origen: Slot = data
	if entregar.is_valid():
		entregar.call(origen, self)
		return
	var item_previo: ParteInventario = item
	poner_item(origen.item)
	origen.poner_item(item_previo)
