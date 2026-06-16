extends Control
class_name DragLayer
## Oberste Ebene: zeichnet das gerade gezogene Item, das dem Mauszeiger folgt.
## 'spin' erzeugt beim Drehen (Rechtsklick) eine weiche 90-Grad-Animation.

var main: Node = null
const CS := 30

# Zusaetzlicher Drehwinkel der Vorschau (Radiant). Wird beim Drehen von
# -90 Grad auf 0 getweent, sodass die Form im Uhrzeigersinn einrastet.
var spin := 0.0

func _set_spin(v: float) -> void:
	spin = v
	queue_redraw()

## Startet die Dreh-Animation (nach rechts).
func start_spin() -> void:
	spin = -PI / 2.0
	var tw := create_tween()
	tw.tween_method(_set_spin, spin, 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if main == null or main.drag == null:
		return
	var d: Dictionary = main.drag
	var mp := get_global_mouse_position() - global_position
	var grid := ShapeUtil.size_of(d.cells)
	var top_left := mp - Vector2(grid.x * CS, grid.y * CS) / 2.0
	ItemArt.draw_piece(self, d.data.kind, d.data.tex, d.data.cells, d.cells, top_left, CS, d.rot, spin)
