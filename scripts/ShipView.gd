extends Control
class_name ShipView
## Statische Anzeige eines Raumschiffs (Module + Systeme), automatisch eingepasst.

var modules: Array = []
var systems: Array = []

func setup(p_modules: Array, p_systems: Array) -> void:
	modules = p_modules
	systems = p_systems
	queue_redraw()

func _draw() -> void:
	if modules.is_empty():
		return
	# Bounding-Box aller Modulzellen.
	var min_x := 1 << 30
	var min_y := 1 << 30
	var max_x := -(1 << 30)
	var max_y := -(1 << 30)
	for m in modules:
		for c in m.cells:
			min_x = min(min_x, c.x)
			min_y = min(min_y, c.y)
			max_x = max(max_x, c.x + 1)
			max_y = max(max_y, c.y + 1)
	var cols := max_x - min_x
	var rows := max_y - min_y
	var pad := 18.0
	var cs: float = min((size.x - 2 * pad) / float(cols), (size.y - 2 * pad) / float(rows))
	cs = clampf(cs, 8.0, 64.0)
	var used := Vector2(cols * cs, rows * cs)
	var origin := (size - used) / 2.0
	var base := Vector2(min_x, min_y)

	var tex := ItemDB.storage_tex()
	for m in modules:
		for c in m.cells:
			var p := origin + (Vector2(c.x, c.y) - base) * cs
			draw_texture_rect(tex, Rect2(p, Vector2(cs, cs)), false)
	# Kommandokern hervorheben.
	for m in modules:
		if m.locked:
			for c in m.cells:
				var p := origin + (Vector2(c.x, c.y) - base) * cs
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(cs - 4, cs - 4)), Color(0.28, 0.95, 0.85), false, 2.0)
	# Systeme.
	for s in systems:
		var tl := origin + (Vector2(s.origin.x, s.origin.y) - base) * cs
		ItemArt.draw_piece(self, s.data.kind, s.data.tex, s.data.cells, s.local_cells, tl, cs, s.rot)
