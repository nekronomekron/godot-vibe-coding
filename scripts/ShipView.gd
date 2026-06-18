extends Control
class_name ShipView
## Statische Anzeige eines Raumschiffs – komplett aus echten Sprite-Nodes aufgebaut
## (Sprite2D fuer Module/Systeme, AnimatedSprite2D fuer Waffen), nicht via _draw.
## Bleibt ein Control, damit es sich ins HUD-Layout einfuegt und die Anflug-Animation
## seine Groesse/Position kennt.

const NATIVE := 64.0 # Pixel pro Zelle in den SVG-Quellen

var modules: Array = []
var systems: Array = []

func _ready() -> void:
	resized.connect(_rebuild)

func setup(p_modules: Array, p_systems: Array) -> void:
	modules = p_modules
	systems = p_systems
	_rebuild()

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _rebuild() -> void:
	_clear()
	if modules.is_empty() or size.x <= 0.0 or size.y <= 0.0:
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
	var cs: float = min((size.x - 2.0 * pad) / float(cols), (size.y - 2.0 * pad) / float(rows))
	cs = clampf(cs, 8.0, 64.0)
	var used := Vector2(cols * cs, rows * cs)
	var origin := (size - used) / 2.0
	var base := Vector2(min_x, min_y)
	var scale_f := cs / NATIVE

	# Module als Sprite2D (Schiffsboden-Tile).
	var tile := ItemDB.storage_tex()
	for m in modules:
		for c in m.cells:
			var spr := Sprite2D.new()
			spr.texture = tile
			spr.scale = Vector2(scale_f, scale_f)
			spr.position = origin + (Vector2(c.x, c.y) - base) * cs + Vector2(cs, cs) / 2.0
			if m.locked:
				spr.modulate = Color(0.55, 1.0, 0.92) # Kommandokern hervorheben
			add_child(spr)

	# Systeme: Waffen animiert (AnimatedSprite2D), Rest statisch (Sprite2D).
	for s in systems:
		var data: Dictionary = s.data
		var grid := ShapeUtil.size_of(s.local_cells)
		var top_left := origin + (Vector2(s.origin.x, s.origin.y) - base) * cs
		var center := top_left + Vector2(grid.x, grid.y) * cs / 2.0
		var node: Node2D
		if data.has("frames"):
			var asp := AnimatedSprite2D.new()
			asp.sprite_frames = data.frames
			asp.play("default")
			node = asp
		else:
			var spr2 := Sprite2D.new()
			spr2.texture = data.tex
			node = spr2
		node.scale = Vector2(scale_f, scale_f)
		node.rotation = s.rot * PI / 2.0
		node.position = center
		add_child(node)
