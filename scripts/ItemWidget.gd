extends Control
class_name ItemWidget
## Kleine Anzeige eines Items/Stauraums im Haendler oder in der Kiste.
## Reine Darstellung - das Ziehen wird zentral in Main.gd erkannt.

var data: Dictionary = {}
var cs := 26

static var _slot_style: StyleBoxFlat

static func _slot() -> StyleBoxFlat:
	if _slot_style == null:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.07, 0.12, 0.16)
		s.set_corner_radius_all(6)
		s.set_border_width_all(1)
		s.border_color = Color(0.16, 0.42, 0.5)
		_slot_style = s
	return _slot_style

func setup(d: Dictionary, cell_px: int) -> void:
	data = d
	cs = cell_px
	var sz := ShapeUtil.size_of(d.cells)
	custom_minimum_size = Vector2(sz.x * cs + 14, sz.y * cs + 28)
	tooltip_text = d.name
	queue_redraw()

func _draw() -> void:
	if data.is_empty():
		return
	# Abgesetzter Slot-Hintergrund.
	draw_style_box(_slot(), Rect2(0, 18, size.x, maxf(0.0, size.y - 18)))
	ItemArt.draw_piece(self, data.kind, data.tex, data.cells, data.cells, Vector2(7, 23), cs, 0)
	draw_string(get_theme_default_font(), Vector2(3, 13), data.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.82, 0.85, 0.92))
