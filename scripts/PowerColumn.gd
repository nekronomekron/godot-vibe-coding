extends Control
class_name PowerColumn
## FTL-artige Energiesaeule eines Subsystems: vertikale Pips (zugewiesen/Kapazitaet).

var sys_name := ""
var allocated := 0
var capacity := 0
var color := Color(0.4, 0.8, 0.9)

func setup(p_name: String, p_alloc: int, p_cap: int, p_color: Color) -> void:
	sys_name = p_name
	allocated = p_alloc
	capacity = p_cap
	color = p_color
	custom_minimum_size = Vector2(52, 96)
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, 12), sys_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.72, 0.82, 0.88))

	var top := 18.0
	var bottom := size.y - 15.0
	var pips: int = max(capacity, 1)
	pips = min(pips, 8)
	var gap := 3.0
	var ph: float = min(16.0, (bottom - top - (pips - 1) * gap) / float(pips))
	var pw := size.x * 0.62
	var px := (size.x - pw) / 2.0
	# Vertiefter Track hinter der Pip-Saeule.
	draw_style_box(HudArt.slot_box(), Rect2(px - 4.0, top - 3.0, pw + 8.0, bottom - top + 6.0))
	var dim := Color(color.r, color.g, color.b, 0.12)
	for i in pips:
		var y := bottom - (i + 1) * ph - i * gap
		var r := Rect2(px, y, pw, ph)
		if i < allocated:
			draw_rect(r, color, true)
			draw_rect(r, Color(1, 1, 1, 0.22), false, 1.0)
		else:
			draw_rect(r, dim, true)
			draw_rect(r, Color(0.3, 0.45, 0.5, 0.5), false, 1.0)

	draw_string(font, Vector2(0, size.y - 2), "%d/%d" % [allocated, capacity], HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.82, 0.9, 0.95))
