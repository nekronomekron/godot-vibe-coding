extends Control
class_name FlyingPiece
## Kurzlebiges Overlay, das ein verdraengtes Item/Stauraum von seiner
## Rucksack-Position in die Kiste gleiten laesst (per Tween in Main.gd gesteuert).
## Baut echte Sprite-Nodes (Waffen animiert), kein _draw.

const NATIVE := 64.0

func setup(kind: int, tex: Texture2D, frames, cells: Array, rot: int, cell_px: float) -> void:
	var sz := ShapeUtil.size_of(cells)
	size = Vector2(sz.x * cell_px, sz.y * cell_px)
	pivot_offset = Vector2.ZERO
	for c in get_children():
		c.queue_free()
	var sf := cell_px / NATIVE
	if kind == ItemDB.Kind.STORAGE:
		# Stauraum: ein Tile pro Zelle.
		for c in cells:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.scale = Vector2(sf, sf)
			spr.position = Vector2(c.x * cell_px + cell_px / 2.0, c.y * cell_px + cell_px / 2.0)
			add_child(spr)
	else:
		# Item: ein (ggf. animiertes) Sprite ueber die Bounding-Box, gedreht.
		var node: Node2D
		if frames != null:
			var asp := AnimatedSprite2D.new()
			asp.sprite_frames = frames
			asp.play("default")
			node = asp
		else:
			var spr2 := Sprite2D.new()
			spr2.texture = tex
			node = spr2
		node.scale = Vector2(sf, sf)
		node.rotation = rot * PI / 2.0
		node.position = Vector2(sz.x, sz.y) * cell_px / 2.0
		add_child(node)
