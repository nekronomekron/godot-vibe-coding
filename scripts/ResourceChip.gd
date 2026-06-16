extends Control
class_name ResourceChip
## Boxen-Anzeige fuer eine Ressource (FTL-artig): grosser Wert + Label + Akzent.

var label_text := ""
var value_text := ""
var accent := Color(0.4, 0.8, 0.9)

func setup(p_label: String, p_value: String, p_accent: Color) -> void:
	label_text = p_label
	value_text = p_value
	accent = p_accent
	custom_minimum_size = Vector2(82, 44)
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	draw_style_box(HudArt.chip_box(), Rect2(0, 0, size.x, size.y))
	draw_rect(Rect2(4, 5, 3, size.y - 10), accent, true)
	draw_string(font, Vector2(6, 23), value_text, HORIZONTAL_ALIGNMENT_CENTER, size.x - 6, 19, Color(0.92, 0.97, 1.0))
	draw_string(font, Vector2(6, size.y - 6), label_text.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 6, 10, Color(0.66, 0.76, 0.83))
