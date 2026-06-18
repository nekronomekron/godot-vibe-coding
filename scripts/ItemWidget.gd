extends Control
class_name ItemWidget
## Kleine Anzeige eines Items/Stauraums im Haendler oder in der Kiste.
## Das Item wird als echtes Sprite-Node dargestellt (Waffen animiert), Slot/Name via _draw.
## Das Ziehen wird zentral in Main.gd erkannt.

const NATIVE := 64.0

var data: Dictionary = {}
var cs := 26
var _sprite: Node2D = null

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
	_build_sprite()
	queue_redraw()

func _build_sprite() -> void:
	if _sprite != null:
		_sprite.queue_free()
		_sprite = null
	if data.is_empty():
		return
	var root := Node2D.new()
	root.position = Vector2(7, 23)
	add_child(root)
	var sf := cs / NATIVE
	if data.kind == ItemDB.Kind.STORAGE:
		# Stauraum: ein Tile pro Zelle.
		for c in data.cells:
			var spr := Sprite2D.new()
			spr.texture = data.tex
			spr.scale = Vector2(sf, sf)
			spr.position = Vector2(c.x + 0.5, c.y + 0.5) * cs
			root.add_child(spr)
	else:
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
		var bbox := ShapeUtil.size_of(data.cells)
		node.scale = Vector2(sf, sf)
		node.position = Vector2(bbox.x, bbox.y) * cs / 2.0
		root.add_child(node)
	_sprite = root

func _draw() -> void:
	if data.is_empty():
		return
	draw_style_box(_slot(), Rect2(0, 18, size.x, maxf(0.0, size.y - 18)))
	draw_string(get_theme_default_font(), Vector2(3, 13), data.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.82, 0.85, 0.92))
