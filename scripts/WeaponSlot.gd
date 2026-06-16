extends Control
class_name WeaponSlot
## Waffen-Slot mit Ladebalken (FTL-artig): Name + Status + segmentierte Aufladung.

var wname := ""
var color := Color(0.95, 0.55, 0.35)
var ratio := 0.0
var charged := false
var no_ammo := false

func setup(p_name: String, p_color: Color) -> void:
	wname = p_name
	color = p_color
	custom_minimum_size = Vector2(0, 32)
	queue_redraw()

func set_charge(p_ratio: float, p_charged: bool, p_no_ammo: bool) -> void:
	ratio = clampf(p_ratio, 0.0, 1.0)
	charged = p_charged
	no_ammo = p_no_ammo
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	draw_string(font, Vector2(2, 13), wname.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.62, 12, Color(0.82, 0.9, 0.95))
	var status := "BEREIT" if charged else ("LEER" if no_ammo else "LAEDT")
	var scol := Color(0.45, 0.95, 0.55) if charged else (Color(0.92, 0.42, 0.42) if no_ammo else Color(0.7, 0.75, 0.6))
	draw_string(font, Vector2(0, 13), status, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2, 11, scol)

	var by := 17.0
	var bh := size.y - by - 1.0
	draw_style_box(HudArt.slot_box(), Rect2(0, by - 1, size.x, bh + 2))

	var pad := 4.0
	var inner_x := pad
	var inner_w := size.x - 2.0 * pad
	var inner_y := by + 1.0
	var inner_h := bh - 2.0
	var segs := 16
	var gap := 2.0
	var sw := (inner_w - (segs - 1) * gap) / float(segs)
	sw = maxf(1.0, sw)
	var lit := int(round(ratio * segs))
	var fill := Color(0.45, 0.95, 0.55) if charged else color
	var dim := Color(fill.r, fill.g, fill.b, 0.13)
	for i in segs:
		var x := inner_x + i * (sw + gap)
		draw_rect(Rect2(x, inner_y, sw, inner_h), fill if i < lit else dim, true)
