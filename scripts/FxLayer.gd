extends Control
class_name FxLayer
## Overlay fuer Gefechts-Effekte: Laserstrahlen, Raketen und Treffer-Impacts.

var fx: Array = []

## Feuert einen Effekt von 'from' nach 'to' (lokale Koordinaten dieser Ebene).
func fire(from: Vector2, to: Vector2, color: Color, missile: bool) -> void:
	if missile:
		fx.append({"kind": "missile", "from": from, "to": to, "color": color, "t": 0.0, "dur": 0.5})
	else:
		fx.append({"kind": "beam", "from": from, "to": to, "color": color, "t": 0.0, "dur": 0.22})
		_impact(to, color)
	set_process(true)
	queue_redraw()

func _impact(pos: Vector2, color: Color) -> void:
	fx.append({"kind": "impact", "pos": pos, "color": color, "t": 0.0, "dur": 0.4})

func _process(delta: float) -> void:
	var alive: Array = []
	for e in fx:
		e.t += delta
		if e.kind == "missile" and e.t >= e.dur:
			alive.append({"kind": "impact", "pos": e.to, "color": e.color, "t": 0.0, "dur": 0.4})
			continue
		if e.t < e.dur:
			alive.append(e)
	fx = alive
	queue_redraw()
	if fx.is_empty():
		set_process(false)

func _draw() -> void:
	for e in fx:
		var k: float = clampf(e.t / e.dur, 0.0, 1.0)
		match e.kind:
			"beam":
				var a := 1.0 - k
				draw_line(e.from, e.to, Color(e.color.r, e.color.g, e.color.b, a * 0.7), 5.0)
				draw_line(e.from, e.to, Color(1, 1, 1, a), 1.5)
			"missile":
				var pos: Vector2 = e.from.lerp(e.to, k)
				var dir: Vector2 = (e.to - e.from).normalized()
				draw_line(pos - dir * 18.0, pos, Color(e.color.r, e.color.g, e.color.b, 0.55), 3.0)
				draw_circle(pos, 8.0, Color(e.color.r, e.color.g, e.color.b, 0.3))
				draw_circle(pos, 4.5, Color(1.0, 0.9, 0.6, 1.0))
			"impact":
				var a := 1.0 - k
				var radius := 6.0 + k * 22.0
				draw_arc(e.pos, radius, 0.0, TAU, 26, Color(e.color.r, e.color.g, e.color.b, a), 2.5)
				draw_circle(e.pos, 6.0 * a + 2.0, Color(1, 1, 1, a))
