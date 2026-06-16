extends Node
## Autoload: haelt die Schiffskonfiguration ueber Szenenwechsel hinweg.
## (Kein class_name, da der Autoload-Knoten bereits 'GameState' heisst.)

var player_modules: Array = [] # [{cells: Array[Vector2i], locked: bool}]
var player_systems: Array = [] # [{data, origin: Vector2i, local_cells: Array, rot: int}]
var intro := false # naechste Battle-Szene soll die Anflug-Animation abspielen

## Uebernimmt die aktuelle Konfiguration aus dem Backpack (Raumschiff-Editor).
func capture_player(backpack) -> void:
	player_modules.clear()
	player_systems.clear()
	for p in backpack.storage_pieces:
		player_modules.append({"cells": p.cells.duplicate(), "locked": p.locked})
	for it in backpack.items:
		player_systems.append({
			"data": it.data,
			"origin": it.origin,
			"local_cells": it.local_cells.duplicate(),
			"rot": it.rot,
		})

func has_player() -> bool:
	return not player_modules.is_empty()

## Naechste freie uid (damit neue Items nach dem Wiederherstellen nicht kollidieren).
func next_uid() -> int:
	var m := 0
	for s in player_systems:
		m = max(m, int(s.data.uid))
	return m + 1
