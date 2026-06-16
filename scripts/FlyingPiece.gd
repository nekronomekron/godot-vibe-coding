extends Control
class_name FlyingPiece
## Kurzlebiges Overlay, das ein verdraengtes Item/Stauraum von seiner
## Rucksack-Position in die Kiste gleiten laesst (per Tween in Main.gd gesteuert).

var kind := 0
var tex: Texture2D = null
var base_cells: Array = []
var cells: Array = []
var rot := 0
var cs := 48.0

func setup(p_kind: int, p_tex: Texture2D, p_base_cells: Array, p_cells: Array, p_rot: int, cell_px: float) -> void:
	kind = p_kind
	tex = p_tex
	base_cells = p_base_cells
	cells = p_cells
	rot = p_rot
	cs = cell_px
	var sz := ShapeUtil.size_of(p_cells)
	size = Vector2(sz.x * cs, sz.y * cs)
	pivot_offset = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	ItemArt.draw_piece(self, kind, tex, base_cells, cells, Vector2.ZERO, cs, rot)
