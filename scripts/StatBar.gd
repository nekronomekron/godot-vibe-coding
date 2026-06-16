extends Control
class_name StatBar
## Segmentierter HUD-Balken (FTL-Stil): Label + Wert + Pip-Reihe.

var label_text := ""
var value_text := ""
var ratio := 1.0
var bar_color := Color(0.36, 0.86, 0.45)
var segments := 16

func setup(p_label: String, p_value: String, p_ratio: float, p_color: Color, p_segments := 16) -> void:
	label_text = p_label
	value_text = p_value
	ratio = clampf(p_ratio, 0.0, 1.0)
	bar_color = p_color
	segments = max(1, p_segments)
	custom_minimum_size = Vector2(0, 30 if label_text == "" else 32)
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var by := 2.0
	if label_text != "":
		draw_string(font, Vector2(2, 12), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.80, 0.86))
		draw_string(font, Vector2(0, 12), value_text, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2, 12, Color(0.88, 0.95, 1.0))
		by = 17.0
	elif value_text != "":
		draw_string(font, Vector2(0, 11), value_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.85, 0.92, 1.0))
		by = 14.0

	var bh := size.y - by - 1.0
	# Vertiefter Track als Hintergrund.
	draw_style_box(HudArt.slot_box(), Rect2(0, by - 1, size.x, bh + 2))

	var pad := 4.0
	var inner_x := pad
	var inner_w := size.x - 2.0 * pad
	var inner_y := by + 1.0
	var inner_h := bh - 2.0
	var gap := 2.0
	var seg_w := (inner_w - (segments - 1) * gap) / float(segments)
	seg_w = maxf(1.0, seg_w)
	var lit := int(round(ratio * segments))
	var dim := Color(bar_color.r, bar_color.g, bar_color.b, 0.13)
	for i in segments:
		var x := inner_x + i * (seg_w + gap)
		draw_rect(Rect2(x, inner_y, seg_w, inner_h), bar_color if i < lit else dim, true)
