extends Control
class_name ShieldRow
## Reihe von Schild-Schichten (FTL-artige blaue Schild-Pips).

var layers := 0

func setup(p_layers: int) -> void:
	layers = p_layers
	custom_minimum_size = Vector2(0, 20)
	queue_redraw()

func _draw() -> void:
	if layers <= 0:
		draw_string(get_theme_default_font(), Vector2(2, 14), "—", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.45, 0.5, 0.55))
		return
	var r := 7.0
	var gap := 7.0
	var cy := size.y / 2.0
	for i in layers:
		var cx := r + 2.0 + i * (2.0 * r + gap)
		draw_circle(Vector2(cx, cy), r, Color(0.26, 0.6, 1.0, 0.22))
		draw_arc(Vector2(cx, cy), r, 0.0, TAU, 28, Color(0.42, 0.78, 1.0, 0.95), 2.0)
