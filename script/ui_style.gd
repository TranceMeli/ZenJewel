# ui_style.gd
# Gemeinsame Farben und Styleboxen, damit Menü, Shop und HUD gleich aussehen.
# Farben stammen aus der bestehenden Top-Bar (Braun) und dem Gold des Wiesenlabels.
class_name UIStyle
extends RefCounted

const FONT = preload("res://font/PressStart2P-Regular.ttf")

const PANEL      = Color(0.165, 0.114, 0.0)
const PANEL_EDGE = Color(0.42, 0.31, 0.06)
const GOLD       = Color(0.726, 0.581, 0.123)
const GOLD_HOVER = Color(0.85, 0.69, 0.2)
const TEXT       = Color(1.0, 0.957, 0.84)
const TEXT_DIM   = Color(0.85, 0.78, 0.6)
const BAD        = Color(1.0, 0.6, 0.56)


static func box(bg: Color, edge: Color = Color(0, 0, 0, 0), radius: int = 8, border: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(border if edge.a > 0.0 else 0)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left   = 14
	sb.content_margin_right  = 14
	sb.content_margin_top    = 8
	sb.content_margin_bottom = 8
	return sb


## Einheitlicher Button: primary = goldene Hauptaktion, sonst dunkel mit Rand.
static func style_button(b: Button, primary: bool = false, size: int = 16) -> void:
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_ALL
	if primary:
		b.add_theme_stylebox_override("normal",   box(GOLD, GOLD))
		b.add_theme_stylebox_override("hover",    box(GOLD_HOVER, GOLD_HOVER))
		b.add_theme_stylebox_override("pressed",  box(GOLD.darkened(0.15), GOLD))
		b.add_theme_stylebox_override("focus",    box(Color(0, 0, 0, 0), TEXT))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(state, PANEL)
	else:
		b.add_theme_stylebox_override("normal",   box(PANEL, PANEL_EDGE))
		b.add_theme_stylebox_override("hover",    box(PANEL.lightened(0.12), GOLD))
		b.add_theme_stylebox_override("pressed",  box(PANEL.darkened(0.2), GOLD))
		b.add_theme_stylebox_override("focus",    box(Color(0, 0, 0, 0), GOLD))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(state, TEXT)
	b.add_theme_stylebox_override("disabled", box(PANEL.darkened(0.2), PANEL_EDGE.darkened(0.3)))
	b.add_theme_color_override("font_disabled_color", TEXT_DIM.darkened(0.4))
