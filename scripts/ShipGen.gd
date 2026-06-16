class_name ShipGen
## Erzeugt zufaellige Raumschiffe aus denselben Modulen/Systemen wie der Editor.
## Nutzt die validierte Platzierungslogik von Backpack (ohne es in den Baum zu haengen).

## Liefert { modules: Array, systems: Array }.
static func generate_ship(system_count: int, module_count: int) -> Dictionary:
	var bp := Backpack.new()
	bp.setup_initial()

	var storage := ItemDB.storage_templates()
	var added := 0
	var attempts := 0
	while added < module_count and attempts < 300:
		attempts += 1
		var rot := randi() % 4
		var cells: Array = storage[randi() % storage.size()].cells.duplicate()
		for r in rot:
			cells = ShapeUtil.rotate_cw(cells)
		var keys := bp.storage_cells.keys()
		var anchor: Vector2i = keys[randi() % keys.size()]
		var origin: Vector2i = anchor + Vector2i(randi_range(-2, 2), randi_range(-2, 2))
		var world: Array = []
		for c in cells:
			world.append(origin + c)
		if bp.can_place_storage(world):
			bp.place_storage(world)
			added += 1

	var systems := ItemDB.item_templates()
	var placed := 0
	attempts = 0
	while placed < system_count and attempts < 500:
		attempts += 1
		var tpl: Dictionary = systems[randi() % systems.size()]
		var rot := randi() % 4
		var cells: Array = tpl.cells.duplicate()
		for r in rot:
			cells = ShapeUtil.rotate_cw(cells)
		var keys := bp.storage_cells.keys()
		var origin: Vector2i = keys[randi() % keys.size()]
		var world: Array = []
		var ok := true
		for c in cells:
			var wc: Vector2i = origin + c
			world.append(wc)
			if not bp.storage_cells.has(wc) or bp.occupancy.has(wc):
				ok = false
				break
		if ok:
			var data: Dictionary = tpl.duplicate(true)
			data["uid"] = 90000 + placed
			bp.place_item(data.uid, data, world, rot)
			placed += 1

	var result := {"modules": [], "systems": []}
	for p in bp.storage_pieces:
		result.modules.append({"cells": p.cells.duplicate(), "locked": p.locked})
	for it in bp.items:
		result.systems.append({
			"data": it.data,
			"origin": it.origin,
			"local_cells": it.local_cells.duplicate(),
			"rot": it.rot,
		})
	bp.free()
	return result
