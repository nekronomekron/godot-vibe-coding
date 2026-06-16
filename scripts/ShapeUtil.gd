class_name ShapeUtil
## Hilfsfunktionen fuer Tetris-aehnliche Formen.
## Eine Form ist ein Array aus Vector2i-Zellen (Offsets ab 0,0).

## Dreht eine Form um 90 Grad nach rechts (im Uhrzeigersinn) und normalisiert sie.
static func rotate_cw(cells: Array) -> Array:
	var rotated: Array = []
	for c in cells:
		# 90 Grad CW: (x, y) -> (-y, x)
		rotated.append(Vector2i(-c.y, c.x))
	return normalize(rotated)

## Verschiebt eine Form so, dass die kleinste Zelle bei (0,0) liegt.
static func normalize(cells: Array) -> Array:
	var min_x := 1000000
	var min_y := 1000000
	for c in cells:
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)
	var out: Array = []
	for c in cells:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	return out

## Liefert die Groesse (Breite, Hoehe) der Bounding-Box einer Form.
static func size_of(cells: Array) -> Vector2i:
	var max_x := 0
	var max_y := 0
	for c in cells:
		max_x = max(max_x, c.x)
		max_y = max(max_y, c.y)
	return Vector2i(max_x + 1, max_y + 1)
