extends Control
class_name Backpack
## Der Rucksack: ein Gitter, in dem Stauraum platziert werden kann.
## In den Stauraum-Zellen koennen wiederum Items platziert werden.

# Grosses logisches Gitter; sichtbar ist nur der Bereich um den Stauraum.
const COLS := 41
const ROWS := 41
const CELL := 48

const ZOOM_MIN := 0.45
const ZOOM_MAX := 2.5
const PAN_PAD := 70.0 # so viel vom Stauraum-Mittelpunkt muss im Sichtfenster bleiben

# Ansicht (Pan in Pixeln, Zoom als Faktor).
var pan := Vector2.ZERO
var zoom := 1.0
var _view_initialized := false

# Stauraum-Zellen: Vector2i -> true
var storage_cells := {}
# Einzelne Stauraum-Teile: { cells: Array[Vector2i] (Welt), locked: bool }
var storage_pieces := []
# Platzierte Items: { uid, data, origin: Vector2i, local_cells: Array[Vector2i], rot: int }
var items := []
# Belegung der Zellen durch Items: Vector2i -> uid
var occupancy := {}

# Vorschau waehrend Drag & Drop
var preview_cells := []
var preview_valid := false
var preview_active := false

func _ready() -> void:
	resized.connect(_on_resized)

func _on_resized() -> void:
	if _view_initialized:
		_clamp_pan()
	queue_redraw()

## Start-Rucksack: ein fest verankerter 2x2-Stauraum in der Mitte.
func setup_initial() -> void:
	var base := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	var origin := Vector2i(COLS / 2 - 1, ROWS / 2 - 1)
	var world: Array = []
	for o in base:
		world.append(origin + o)
	_add_storage(world, true)
	queue_redraw()

func _add_storage(world_cells: Array, locked: bool) -> void:
	storage_pieces.append({"cells": world_cells.duplicate(), "locked": locked})
	for wc in world_cells:
		storage_cells[wc] = true

## Stellt eine gespeicherte Konfiguration wieder her (Module + Systeme).
func load_config(modules: Array, systems: Array) -> void:
	storage_cells.clear()
	storage_pieces.clear()
	items.clear()
	occupancy.clear()
	_view_initialized = false
	for m in modules:
		_add_storage(m.cells.duplicate(), m.locked)
	for s in systems:
		var world: Array = []
		for lc in s.local_cells:
			world.append(s.origin + lc)
		place_item(int(s.data.uid), s.data, world, int(s.rot))
	queue_redraw()

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS

## Bildschirm-Position (lokal im Control) -> Gitterzelle (beruecksichtigt Pan/Zoom).
func cell_at_local(p: Vector2) -> Vector2i:
	var world := (p - pan) / zoom
	return Vector2i(int(floor(world.x / CELL)), int(floor(world.y / CELL)))

# --- Ansicht: Pan & Zoom -------------------------------------------------

func pan_by(delta: Vector2) -> void:
	pan += delta
	_clamp_pan()
	queue_redraw()

## Zoomt um den Punkt 'local' (Position im Control), sodass dieser fix bleibt.
func zoom_at(local: Vector2, factor: float) -> void:
	var new_zoom := clampf(zoom * factor, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, zoom):
		return
	var world := (local - pan) / zoom
	zoom = new_zoom
	pan = local - world * zoom
	_clamp_pan()
	queue_redraw()

## Bounding-Box aller Stauraum-Zellen in Welt-Pixeln.
func _storage_bbox() -> Rect2:
	if storage_cells.is_empty():
		return Rect2(0, 0, CELL, CELL)
	var min_x := 1.0e20
	var min_y := 1.0e20
	var max_x := -1.0e20
	var max_y := -1.0e20
	for c in storage_cells:
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)
		max_x = max(max_x, c.x + 1)
		max_y = max(max_y, c.y + 1)
	return Rect2(min_x * CELL, min_y * CELL, (max_x - min_x) * CELL, (max_y - min_y) * CELL)

## Verhindert, dass der Stauraum komplett aus dem Sichtfenster geschoben wird:
## der Mittelpunkt der Stauraum-Box bleibt mit PAN_PAD Abstand im Control.
func _clamp_pan() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var bb := _storage_bbox()
	var center_world := bb.position + bb.size / 2.0
	var center_screen := center_world * zoom + pan
	var clamped := Vector2(
		clampf(center_screen.x, PAN_PAD, max(PAN_PAD, size.x - PAN_PAD)),
		clampf(center_screen.y, PAN_PAD, max(PAN_PAD, size.y - PAN_PAD)))
	pan += clamped - center_screen

## Zentriert die Stauraum-Box beim ersten Zeichnen im Control.
func _ensure_view() -> void:
	if _view_initialized or size.x <= 0.0:
		return
	var bb := _storage_bbox()
	var center_world := bb.position + bb.size / 2.0
	pan = size / 2.0 - center_world * zoom
	_view_initialized = true

func _neighbors(c: Vector2i) -> Array:
	return [c + Vector2i(1, 0), c + Vector2i(-1, 0), c + Vector2i(0, 1), c + Vector2i(0, -1)]

# --- Stauraum platzieren -------------------------------------------------

## Stauraum darf nur an bestehenden Stauraum angrenzen (mind. eine Zelle).
func can_place_storage(world_cells: Array) -> bool:
	for wc in world_cells:
		if not in_bounds(wc):
			return false
		if storage_cells.has(wc):
			return false
	var touches := false
	for wc in world_cells:
		for n in _neighbors(wc):
			if storage_cells.has(n):
				touches = true
				break
		if touches:
			break
	return touches

func place_storage(world_cells: Array) -> void:
	_add_storage(world_cells, false)
	queue_redraw()

# --- Items platzieren ----------------------------------------------------

## Items muessen komplett auf Stauraum liegen. Bereits dort liegende Items
## werden beim Platzieren verdraengt (-> Kiste), daher blockiert Belegung NICHT.
func can_place_item(world_cells: Array) -> bool:
	for wc in world_cells:
		if not storage_cells.has(wc):
			return false
	return true

## Verdraengt alle Items, die auf den gegebenen Zellen liegen, und gibt
## Flug-Eintraege zurueck (fuer die Animation in die Kiste).
func displace_items_at(world_cells: Array) -> Array:
	var removed := {}
	for wc in world_cells:
		removed[wc] = true
	var entries := _displace_items_on(removed)
	if not entries.is_empty():
		queue_redraw()
	return entries

func place_item(uid: int, data: Dictionary, world_cells: Array, rot: int) -> void:
	var min_x := 1000000
	var min_y := 1000000
	for wc in world_cells:
		min_x = min(min_x, wc.x)
		min_y = min(min_y, wc.y)
	var origin := Vector2i(min_x, min_y)
	var local: Array = []
	for wc in world_cells:
		local.append(wc - origin)
	items.append({"uid": uid, "data": data, "origin": origin, "local_cells": local, "rot": rot})
	for wc in world_cells:
		occupancy[wc] = uid
	queue_redraw()

## Hebt ein Item an der Zelle auf und gibt es zurueck (oder null).
func pick_item_at(cell: Vector2i):
	if not occupancy.has(cell):
		return null
	var uid = occupancy[cell]
	var idx := -1
	for i in range(items.size()):
		if items[i].uid == uid:
			idx = i
			break
	if idx == -1:
		return null
	var it = items[idx]
	for lc in it.local_cells:
		occupancy.erase(it.origin + lc)
	items.remove_at(idx)
	queue_redraw()
	return it

## Hebt ein nicht-verankertes Stauraum-Teil auf.
## Items auf diesem Teil werden verdraengt. Zusaetzlich wird geprueft, ob das
## Gitter dadurch "auseinanderbricht": Stauraum, der nicht mehr mit dem
## verankerten Start-Stauraum verbunden ist, wird ebenfalls geloest.
##
## Rueckgabe (oder null, wenn an der Zelle kein loesbarer Stauraum liegt):
##   {
##     local_cells:      Array  - normalisierte Form des aufgenommenen Teils (zum Ziehen)
##     items_to_chest:   Array  - Item-Daten, die in die Kiste muessen
##     storage_to_chest: Array  - Array aus normalisierten Zell-Arrays loser Stauraum-Teile
##   }
func pick_storage_at(cell: Vector2i):
	var picked_idx := -1
	for i in range(storage_pieces.size()):
		var pc = storage_pieces[i]
		if not pc.locked and cell in pc.cells:
			picked_idx = i
			break
	if picked_idx == -1:
		return null

	var picked_cells: Array = storage_pieces[picked_idx].cells.duplicate()
	storage_pieces.remove_at(picked_idx)
	for wc in picked_cells:
		storage_cells.erase(wc)

	# Verbindung zum verankerten Stauraum bestimmen.
	var reachable := _reachable_from_locked()
	var still: Array = []
	var loose_pieces: Array = []
	for pc in storage_pieces:
		if pc.locked:
			still.append(pc)
			continue
		var connected := false
		for wc in pc.cells:
			if reachable.has(wc):
				connected = true
				break
		if connected:
			still.append(pc)
		else:
			loose_pieces.append(pc)
	storage_pieces = still

	# Entfernte Zellen sammeln (aufgenommenes Teil + lose Teile).
	var removed := {}
	for wc in picked_cells:
		removed[wc] = true
	var loose_entries: Array = []
	for pc in loose_pieces:
		var norm := ShapeUtil.normalize(pc.cells)
		loose_entries.append({
			"kind": ItemDB.Kind.STORAGE,
			"data": null, # null -> Main erzeugt neuen Stauraum-Eintrag
			"cells": norm,
			"base_cells": norm,
			"tex": ItemDB.storage_tex(),
			"rot": 0,
			"world_cells": pc.cells.duplicate(),
		})
		for wc in pc.cells:
			removed[wc] = true
			storage_cells.erase(wc)

	# Alle Items, die auf entferntem Stauraum liegen, verdraengen.
	var displaced := _displace_items_on(removed)
	displaced.append_array(loose_entries)

	queue_redraw()
	return {
		"local_cells": ShapeUtil.normalize(picked_cells),
		"displaced": displaced,
	}

## Flood-Fill ueber die Stauraum-Zellen, ausgehend von den verankerten Teilen.
func _reachable_from_locked() -> Dictionary:
	var reachable := {}
	var stack: Array = []
	for pc in storage_pieces:
		if pc.locked:
			for wc in pc.cells:
				if storage_cells.has(wc) and not reachable.has(wc):
					reachable[wc] = true
					stack.append(wc)
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for n in _neighbors(c):
			if storage_cells.has(n) and not reachable.has(n):
				reachable[n] = true
				stack.append(n)
	return reachable

## Entfernt alle Items, die mindestens eine Zelle in 'removed' haben, und gibt
## Flug-Eintraege zurueck (inkl. Weltzellen fuer die Animation in die Kiste).
func _displace_items_on(removed: Dictionary) -> Array:
	var out: Array = []
	var keep: Array = []
	for it in items:
		var hit := false
		for lc in it.local_cells:
			if removed.has(it.origin + lc):
				hit = true
				break
		if hit:
			var world: Array = []
			for lc in it.local_cells:
				world.append(it.origin + lc)
			out.append({
				"kind": ItemDB.Kind.ITEM,
				"data": it.data,
				"cells": it.local_cells,
				"base_cells": it.data.cells,
				"tex": it.data.tex,
				"rot": it.rot,
				"world_cells": world,
			})
			for lc in it.local_cells:
				occupancy.erase(it.origin + lc)
		else:
			keep.append(it)
	items = keep
	return out

# --- Vorschau ------------------------------------------------------------

func set_preview(world_cells: Array, valid: bool) -> void:
	preview_cells = world_cells
	preview_valid = valid
	preview_active = true
	queue_redraw()

func clear_preview() -> void:
	preview_active = false
	queue_redraw()

# --- Zeichnen ------------------------------------------------------------

## Berechnet die "angedeuteten" freien Zellen rund um den Stauraum mit Alpha-Falloff
## (voll nahe am Stauraum, ausblendend bis ~2 Zellen Abstand).
func _compute_halo() -> Dictionary:
	var halo := {}
	for sc in storage_cells:
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if dx == 0 and dy == 0:
					continue
				var cell: Vector2i = sc + Vector2i(dx, dy)
				if storage_cells.has(cell) or not in_bounds(cell):
					continue
				var d := sqrt(float(dx * dx + dy * dy))
				var a := clampf((2.3 - d) / 1.3, 0.0, 1.0) * 0.5
				if a <= 0.01:
					continue
				halo[cell] = maxf(halo.get(cell, 0.0), a)
	return halo

func _cell_rect(cell: Vector2i, cs: float) -> Rect2:
	return Rect2(Vector2(cell.x * CELL, cell.y * CELL) * zoom + pan, Vector2(cs, cs))

func _draw() -> void:
	_ensure_view()
	var storage_tex := ItemDB.storage_tex()
	var cs := CELL * zoom

	# Angedeutete freie Andock-Zellen rund um die Module (dezenter Geister-Slot).
	var halo := _compute_halo()
	for cell in halo:
		var a: float = halo[cell]
		var rect := _cell_rect(cell, cs).grow(-2.0)
		draw_rect(rect, Color(0.20, 0.55, 0.65, a * 0.10), true)
		draw_rect(rect, Color(0.32, 0.82, 0.92, a * 0.5), false, maxf(1.0, zoom))

	# Stauraum-Zellen (Tile-Textur).
	for wc in storage_cells.keys():
		draw_texture_rect(storage_tex, _cell_rect(wc, cs), false)

	# Verankerten Start-Stauraum hervorheben.
	for pc in storage_pieces:
		if pc.locked:
			for wc in pc.cells:
				var r := _cell_rect(wc, cs)
				draw_rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), Color(0.28, 0.95, 0.85), false, maxf(1.5, 2.0 * zoom))

	# Platzierte Items (Sprite ueber die Bounding-Box, gedreht).
	for it in items:
		var top_left := Vector2(it.origin.x * CELL, it.origin.y * CELL) * zoom + pan
		ItemArt.draw_piece(self, ItemDB.Kind.ITEM, it.data.tex, it.data.cells, it.local_cells, top_left, cs, it.rot)

	# Vorschau (gruen = moeglich, rot = nicht moeglich).
	if preview_active:
		var col := Color(0.20, 0.90, 0.30, 0.45) if preview_valid else Color(0.95, 0.20, 0.20, 0.45)
		for wc in preview_cells:
			draw_rect(_cell_rect(wc, cs), col, true)
