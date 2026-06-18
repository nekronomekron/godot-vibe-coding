extends Control
class_name DragLayer
## Oberste Ebene: zeigt das gerade gezogene Item als Sprite-Node(s) (Waffen animiert),
## das dem Mauszeiger folgt. Stauraum wird als ein Tile pro Zelle dargestellt.
## 'spin' erzeugt beim Drehen (Rechtsklick) eine weiche 90-Grad-Animation.

const NATIVE := 64.0
const CS := 30

var main: Node = null
var spin := 0.0
var _sprite: Node2D = null
var _cur_data = null
var _cur_cells: Array = []

func _process(_delta: float) -> void:
	if main == null or main.drag == null:
		_free_sprite()
		return
	var d: Dictionary = main.drag
	var rebuild: bool = d.data != _cur_data
	if d.data.kind == ItemDB.Kind.STORAGE and d.cells != _cur_cells:
		rebuild = true
	if rebuild:
		_build_sprite(d.data, d.cells)
		_cur_data = d.data
		_cur_cells = d.cells.duplicate()
	if _sprite != null:
		_sprite.position = get_local_mouse_position()
		if d.data.kind == ItemDB.Kind.STORAGE:
			_sprite.rotation = spin # Zellen sind bereits rotiert
		else:
			_sprite.rotation = d.rot * PI / 2.0 + spin

func _free_sprite() -> void:
	if _sprite != null:
		_sprite.queue_free()
		_sprite = null
	_cur_data = null
	_cur_cells = []

func _build_sprite(data: Dictionary, cells: Array) -> void:
	_free_sprite()
	var root := Node2D.new()
	add_child(root)
	var sf := CS / NATIVE
	if data.kind == ItemDB.Kind.STORAGE:
		# Stauraum: ein Tile pro Zelle, um den Mauszeiger zentriert.
		var grid := ShapeUtil.size_of(cells)
		var center := Vector2(grid.x, grid.y) * CS / 2.0
		for c in cells:
			var spr := Sprite2D.new()
			spr.texture = data.tex
			spr.scale = Vector2(sf, sf)
			spr.position = Vector2(c.x + 0.5, c.y + 0.5) * CS - center
			root.add_child(spr)
	else:
		# Item: ein (ggf. animiertes) Sprite, um den Mauszeiger zentriert.
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
		node.scale = Vector2(sf, sf)
		root.add_child(node)
	_sprite = root

func _set_spin(v: float) -> void:
	spin = v

## Startet die Dreh-Animation (nach rechts).
func start_spin() -> void:
	spin = -PI / 2.0
	var tw := create_tween()
	tw.tween_method(_set_spin, spin, 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
