extends RefCounted

const TINTA = Color(0.20, 0.16, 0.11)

static func papel() -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = preload("res://sprites/INTERFAZ-MENU/torsosinv.png")
	# La hoja de SHIFT, sin las pestañas impresas ni el margen transparente.
	estilo.region_rect = Rect2(1655, 245, 1465, 1900)
	estilo.set_texture_margin_all(24)
	estilo.set_content_margin_all(30)
	return estilo

static func recorte(tinte: Color) -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = preload("res://sprites/INTERFAZ-MENU/boton2 (1).png")
	estilo.region_rect = Rect2(220, 840, 1200, 740)
	estilo.modulate_color = tinte
	estilo.set_content_margin_all(10)
	return estilo

static func marca(alpha: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.27, 0.17, 0.09, alpha)
	estilo.border_color = Color(0.35, 0.17, 0.10, minf(alpha * 4.0, 0.9))
	estilo.border_width_bottom = 2
	return estilo

static func crear_tema() -> Theme:
	var tema := Theme.new()
	tema.default_font = preload("res://Assets/tox_typewriter/Tox Typewriter.ttf")
	tema.default_font_size = 18
	for tipo in ["Label", "Button", "ItemList"]:
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_selected_color"]:
			tema.set_color(color, tipo, TINTA)
		tema.set_color("font_disabled_color", tipo, Color(0.38, 0.33, 0.26, 0.65))
	tema.set_stylebox("normal", "Button", recorte(Color.WHITE))
	tema.set_stylebox("hover", "Button", recorte(Color(1.05, 1.02, 0.92)))
	tema.set_stylebox("pressed", "Button", recorte(Color(0.8, 0.74, 0.61)))
	tema.set_stylebox("hover_pressed", "Button", recorte(Color(0.8, 0.74, 0.61)))
	tema.set_stylebox("disabled", "Button", recorte(Color(0.9, 0.86, 0.77, 0.6)))
	tema.set_stylebox("focus", "Button", marca(0.08))
	tema.set_type_variation("Oferta", "Button")
	for estado in ["normal", "disabled"]:
		tema.set_stylebox(estado, "Oferta", StyleBoxEmpty.new())
	tema.set_stylebox("hover", "Oferta", marca(0.08))
	for estado in ["pressed", "hover_pressed"]:
		tema.set_stylebox(estado, "Oferta", marca(0.18))
	tema.set_stylebox("panel", "ItemList", StyleBoxEmpty.new())
	tema.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	for estado in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		tema.set_stylebox(estado, "ItemList", marca(0.18))
	tema.set_stylebox("hovered", "ItemList", marca(0.06))
	var borde_dialogo := papel()
	borde_dialogo.expand_margin_top = 30
	tema.set_stylebox("embedded_border", "Window", borde_dialogo)
	tema.set_stylebox("embedded_unfocused_border", "Window", borde_dialogo)
	tema.set_stylebox("panel", "AcceptDialog", papel())
	tema.set_color("title_color", "Window", TINTA)
	return tema
