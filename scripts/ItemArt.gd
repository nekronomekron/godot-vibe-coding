class_name ItemArt
## Gemeinsame Zeichenroutine fuer Items und Stauraum (Texturen) –
## genutzt von Backpack, ItemWidget, FlyingPiece und DragLayer.

const CELL_FILL := Color(0.20, 0.80, 0.90, 0.09)  # leichter Slot-Hintergrund pro Zelle (cyan)
const CELL_BORDER := Color(0.32, 0.86, 1.0, 0.34)  # Zell-Trennlinien (ueber dem Sprite)

## Zeichnet ein Teil in einen CanvasItem.
## - kind:       ItemDB.Kind.STORAGE oder .ITEM
## - tex:        Textur (Item-Sprite bzw. Stauraum-Tile)
## - base_cells: Grundform (unrotiert) – bestimmt die Sprite-Groesse bei Items
## - cells:      aktuelle (ggf. rotierte) Zellen – bestimmen die Grundflaeche
## - top_left:   obere linke Ecke in Pixeln
## - cell:       Zellgroesse in Pixeln
## - rot:        Rotationsschritte (0-3) fuer Item-Sprites
## - spin:       zusaetzlicher Animationswinkel (Radiant)
static func draw_piece(ci: CanvasItem, kind: int, tex: Texture2D, base_cells: Array, cells: Array, top_left: Vector2, cell: float, rot: int, spin: float = 0.0) -> void:
	if tex == null:
		return
	if kind == ItemDB.Kind.STORAGE:
		# Stauraum: Tile pro Zelle (zeigt die Zellen bereits selbst).
		_for_each_cell(ci, cells, top_left, cell, spin, func(r): ci.draw_texture_rect(tex, r, false))
		return

	# Item: Zell-Hintergrund -> Sprite -> Zell-Trennlinien obenauf,
	# damit immer ersichtlich ist, wie viele Zellen das Item belegt.
	_for_each_cell(ci, cells, top_left, cell, spin, func(r): ci.draw_rect(r.grow(-1.0), CELL_FILL, true))

	var base := ShapeUtil.size_of(base_cells)
	var grid := ShapeUtil.size_of(cells)
	var center := top_left + Vector2(grid.x * cell, grid.y * cell) / 2.0
	var w := float(base.x) * cell
	var h := float(base.y) * cell
	ci.draw_set_transform(center, rot * PI / 2.0 + spin, Vector2.ONE)
	ci.draw_texture_rect(tex, Rect2(-w / 2.0, -h / 2.0, w, h), false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_for_each_cell(ci, cells, top_left, cell, spin, func(r): ci.draw_rect(r.grow(-1.0), CELL_BORDER, false, maxf(1.0, cell / 28.0)))

## Ruft 'fn(Rect2)' fuer jede Zelle auf; beruecksichtigt die Dreh-Animation (spin).
static func _for_each_cell(ci: CanvasItem, cells: Array, top_left: Vector2, cell: float, spin: float, fn: Callable) -> void:
	if is_zero_approx(spin):
		for c in cells:
			fn.call(Rect2(top_left + Vector2(c.x * cell, c.y * cell), Vector2(cell, cell)))
	else:
		var grid := ShapeUtil.size_of(cells)
		var center := top_left + Vector2(grid.x * cell, grid.y * cell) / 2.0
		var half := Vector2(grid.x * cell, grid.y * cell) / 2.0
		ci.draw_set_transform(center, spin, Vector2.ONE)
		for c in cells:
			fn.call(Rect2(Vector2(c.x * cell, c.y * cell) - half, Vector2(cell, cell)))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
