class_name Slot
extends PanelContainer

signal item_cambiado(slot: Slot)

@export var tag_requerido: String = ""   # "" = acepta cualquier parte

@onready var icono: TextureRect = $Icono

var item: ParteInventario

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.25, 0.2, 0.15)
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(2)
	add_theme_stylebox_override("panel", estilo)

func poner_item(nuevo: ParteInventario) -> void:
	item = nuevo
	icono.texture = nuevo.textura if nuevo else null
	item_cambiado.emit(self)

func acepta(candidato: ParteInventario) -> bool:
	if candidato == null:
		return true
	return tag_requerido == "" or candidato.tags.has(tag_requerido)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	var preview := TextureRect.new()
	preview.texture = item.textura
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)
	return self

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Slot or data == self:
		return false
	var origen: Slot = data
	return acepta(origen.item) and origen.acepta(item)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var origen: Slot = data
	var item_previo: ParteInventario = item
	poner_item(origen.item)
	origen.poner_item(item_previo)
