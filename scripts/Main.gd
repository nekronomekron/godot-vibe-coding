extends Control
## Backpack Builder - Hauptbildschirm.
## Das Layout kommt aus Main.tscn; hier laeuft die zentrale Drag-&-Drop-Logik
## (Aufnehmen, Vorschau, Rotation per Rechtsklick, Ablegen, Flug in die Kiste).

const W_CELL := 26 # Zellgroesse der Item-Vorschauen im Haendler/Kiste

const ITEM_WIDGET := preload("res://scenes/ItemWidget.tscn")
const FLYING_PIECE := preload("res://scenes/FlyingPiece.tscn")

@onready var backpack: Backpack = %Backpack
@onready var merchant_panel: PanelContainer = %MerchantPanel
@onready var merchant_flow: HFlowContainer = %MerchantFlow
@onready var chest_panel: PanelContainer = %ChestPanel
@onready var chest_flow: HFlowContainer = %ChestFlow
@onready var fly_layer: Control = %FlyLayer
@onready var drag_layer: DragLayer = %DragLayer

var merchant_items: Array = [] # Angebot des Haendlers
var chest_items: Array = []    # nicht platzierte Items
var uid_counter := 0

# Aktueller Drag-Zustand:
# { data: Dictionary, cells: Array (rotiert), rot: int, source: String }
var drag = null

# Rucksack verschieben (Pan).
var panning := false
var pan_last := Vector2.ZERO
const ZOOM_STEP := 1.12

func _ready() -> void:
	# Vorhandene Schiffskonfiguration wiederherstellen (z. B. Rueckkehr aus dem Kampf).
	if GameState.has_player():
		backpack.load_config(GameState.player_modules, GameState.player_systems)
		uid_counter = GameState.next_uid()
	else:
		backpack.setup_initial()
	drag_layer.main = self
	%RefreshButton.pressed.connect(_on_refresh_merchant)
	%BattleButton.pressed.connect(_on_battle)
	_on_refresh_merchant()
	_rebuild_chest()

var _launching := false

## Start-Animation: UI fliegt raus, das Schiff beschleunigt nach rechts, dann Szenenwechsel.
func _on_battle() -> void:
	if _launching:
		return
	_launching = true
	%BattleButton.disabled = true
	GameState.capture_player(backpack)
	GameState.intro = true

	var vp := get_viewport_rect().size
	# Helden-Schiff als Overlay ueber dem Editor-Schiff.
	var hero := ShipView.new()
	hero.setup(GameState.player_modules, GameState.player_systems)
	hero.size = Vector2(440, 340)
	hero.position = backpack.get_global_rect().get_center() - hero.size / 2.0 - fly_layer.global_position
	fly_layer.add_child(hero)

	var tw := create_tween()
	tw.set_parallel(true)
	# Gesamte Editor-UI fliegt nach oben raus + blendet aus.
	tw.tween_property($Root, "position:y", -vp.y, 0.42).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property($Root, "modulate:a", 0.0, 0.40)
	# Schiff beschleunigt nach rechts aus dem Bild.
	tw.tween_property(hero, "position:x", vp.x + 480.0, 0.62).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).set_delay(0.06)
	tw.set_parallel(false)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Battle.tscn"))

# --- Item-Instanzen ------------------------------------------------------

func _new_instance(template: Dictionary) -> Dictionary:
	var d := template.duplicate(true)
	d["uid"] = uid_counter
	uid_counter += 1
	return d

func _has_uid(arr: Array, uid: int) -> bool:
	for d in arr:
		if d.uid == uid:
			return true
	return false

func _remove_from(arr: Array, uid: int) -> void:
	for i in range(arr.size()):
		if arr[i].uid == uid:
			arr.remove_at(i)
			return

# --- Haendler / Kiste neu aufbauen --------------------------------------

func _on_refresh_merchant() -> void:
	merchant_items.clear()
	for t in ItemDB.random_offer(6):
		merchant_items.append(_new_instance(t))
	_rebuild_merchant()

func _rebuild_merchant() -> void:
	for c in merchant_flow.get_children():
		c.queue_free()
	for d in merchant_items:
		var w: ItemWidget = ITEM_WIDGET.instantiate()
		merchant_flow.add_child(w)
		w.setup(d, W_CELL)

func _rebuild_chest() -> void:
	for c in chest_flow.get_children():
		c.queue_free()
	for d in chest_items:
		var w: ItemWidget = ITEM_WIDGET.instantiate()
		chest_flow.add_child(w)
		w.setup(d, W_CELL)

# --- Eingabe / Drag & Drop ----------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var gpos: Vector2 = event.global_position
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_try_start_drag(gpos)
				else:
					if drag != null:
						_drop(gpos)
					panning = false
			MOUSE_BUTTON_MIDDLE:
				# Mittlere Maustaste verschiebt den Rucksack ueberall.
				if event.pressed and drag == null and _over_backpack(gpos):
					panning = true
					pan_last = gpos
				elif not event.pressed:
					panning = false
			MOUSE_BUTTON_RIGHT:
				if event.pressed and drag != null:
					# Form um 90 Grad nach rechts drehen (mit Animation)
					drag.rot = (drag.rot + 1) % 4
					drag.cells = ShapeUtil.rotate_cw(drag.cells)
					drag_layer.start_spin()
					_update_preview(get_global_mouse_position())
					drag_layer.queue_redraw()
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed and drag == null and _over_backpack(gpos):
					backpack.zoom_at(gpos - backpack.global_position, ZOOM_STEP)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed and drag == null and _over_backpack(gpos):
					backpack.zoom_at(gpos - backpack.global_position, 1.0 / ZOOM_STEP)
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if drag != null:
			_update_preview(event.global_position)
			drag_layer.queue_redraw()
		elif panning:
			backpack.pan_by(event.global_position - pan_last)
			pan_last = event.global_position

func _over_backpack(gpos: Vector2) -> bool:
	return backpack.get_global_rect().has_point(gpos)

func _try_start_drag(gpos: Vector2) -> void:
	# 1) Aus dem Rucksack aufnehmen
	if backpack.get_global_rect().has_point(gpos):
		var local := gpos - backpack.global_position
		var cell := backpack.cell_at_local(local)
		var it = backpack.pick_item_at(cell)
		if it != null:
			drag = {"data": it.data, "cells": it.local_cells.duplicate(), "rot": it.rot, "source": "backpack_item"}
			drag_layer.spin = 0.0
			_update_preview(gpos)
			drag_layer.queue_redraw()
			return
		var res = backpack.pick_storage_at(cell)
		if res != null:
			# Verdraengte Items / loser Stauraum gleiten animiert in die Kiste.
			if not res.displaced.is_empty():
				_animate_to_chest(res.displaced)
			var local_cells: Array = res.local_cells
			var data := _new_instance(ItemDB.make_storage(local_cells))
			drag = {"data": data, "cells": local_cells, "rot": 0, "source": "backpack_storage"}
			drag_layer.spin = 0.0
			_update_preview(gpos)
			drag_layer.queue_redraw()
			return
		# Leere Flaeche im Rucksack -> verschieben (Pan).
		panning = true
		pan_last = gpos
		return

	# 2) Aus dem Haendler aufnehmen
	for w in merchant_flow.get_children():
		if w is ItemWidget and w.get_global_rect().has_point(gpos):
			drag = {"data": w.data, "cells": ShapeUtil.normalize(w.data.cells.duplicate()), "rot": 0, "source": "merchant"}
			drag_layer.spin = 0.0
			drag_layer.queue_redraw()
			return

	# 3) Aus der Kiste aufnehmen
	for w in chest_flow.get_children():
		if w is ItemWidget and w.get_global_rect().has_point(gpos):
			drag = {"data": w.data, "cells": ShapeUtil.normalize(w.data.cells.duplicate()), "rot": 0, "source": "chest"}
			drag_layer.spin = 0.0
			drag_layer.queue_redraw()
			return

func _origin_for(local: Vector2) -> Vector2i:
	var sz := ShapeUtil.size_of(drag.cells)
	var cursor_cell := backpack.cell_at_local(local)
	return cursor_cell - Vector2i(sz.x / 2, sz.y / 2)

func _update_preview(gpos: Vector2) -> void:
	if drag == null:
		return
	if backpack.get_global_rect().has_point(gpos):
		var local := gpos - backpack.global_position
		var origin := _origin_for(local)
		var world: Array = []
		for c in drag.cells:
			world.append(origin + c)
		var valid: bool
		if drag.data.kind == ItemDB.Kind.STORAGE:
			valid = backpack.can_place_storage(world)
		else:
			valid = backpack.can_place_item(world)
		backpack.set_preview(world, valid)
	else:
		backpack.clear_preview()

func _drop(gpos: Vector2) -> void:
	_update_preview(gpos)

	# 1) Gueltige Platzierung im Rucksack.
	if backpack.get_global_rect().has_point(gpos) and backpack.preview_active and backpack.preview_valid:
		if drag.data.kind == ItemDB.Kind.STORAGE:
			backpack.place_storage(backpack.preview_cells.duplicate())
		else:
			# Bereits dort liegende Items in die Kiste schieben (mit Flug-Animation).
			var displaced := backpack.displace_items_at(backpack.preview_cells)
			if not displaced.is_empty():
				_animate_to_chest(displaced)
			backpack.place_item(drag.data.uid, drag.data, backpack.preview_cells.duplicate(), drag.rot)
		_consume_source()
		_end_drag()
		return

	# 2) Keine gueltige Platzierung -> Item fliegt in die Kiste (oder Abbruch).
	#    Auch ein Item, das "neben dem Stauraum" landet, gleitet so in die Kiste.
	var over_merchant := merchant_panel.get_global_rect().has_point(gpos)
	match drag.source:
		"merchant":
			# Abbruch nur, wenn ueber dem Haendler losgelassen; sonst erwerben.
			if not over_merchant:
				_remove_from(merchant_items, drag.data.uid)
				_rebuild_merchant()
				_fly_drag_to_chest(gpos)
		"chest":
			# Liegt bereits in der Kiste -> nichts zu tun.
			pass
		_:
			# backpack_item / backpack_storage: wurde aus dem Rucksack entfernt.
			_fly_drag_to_chest(gpos)

	_end_drag()

func _end_drag() -> void:
	drag = null
	backpack.clear_preview()
	drag_layer.queue_redraw()

## Entfernt das gerade platzierte Item aus seiner Quelle.
func _consume_source() -> void:
	match drag.source:
		"merchant":
			_remove_from(merchant_items, drag.data.uid)
			_rebuild_merchant()
		"chest":
			_remove_from(chest_items, drag.data.uid)
			_rebuild_chest()
		# backpack_item / backpack_storage: bereits beim Aufnehmen entfernt

## Laesst das aktuell gezogene Item von der Mausposition in die Kiste fliegen.
func _fly_drag_to_chest(gpos: Vector2) -> void:
	var cells: Array = drag.cells
	var sz := ShapeUtil.size_of(cells)
	# Der Ghost wird in DragLayer um den Mauszeiger zentriert gezeichnet.
	var off := Vector2(sz.x * DragLayer.CS / 2.0, sz.y * DragLayer.CS / 2.0)
	var start := gpos - off
	var entry := {
		"kind": drag.data.kind,
		"data": drag.data,
		"cells": cells,
		"base_cells": drag.data.cells,
		"tex": drag.data.tex,
		"rot": drag.rot,
	}
	_fly_to_chest(entry, start, DragLayer.CS)

# --- Flug-Animation in die Kiste ----------------------------------------

## Laesst verdraengte Items / losen Stauraum von ihrer Rucksack-Position in die
## Kiste gleiten. Erst nach dem Flug landen sie als Kisten-Eintrag.
func _animate_to_chest(entries: Array) -> void:
	var i := 0
	for e in entries:
		# Startposition = obere linke Zelle der Form im Rucksack (global, mit Pan/Zoom).
		var min_x := 1 << 30
		var min_y := 1 << 30
		for wc in e.world_cells:
			min_x = min(min_x, wc.x)
			min_y = min(min_y, wc.y)
		var world_px := Vector2(min_x * backpack.CELL, min_y * backpack.CELL)
		var start := backpack.global_position + world_px * backpack.zoom + backpack.pan
		# Leichter zeitlicher Versatz, wenn mehrere Teile gleichzeitig fliegen.
		_fly_to_chest(e, start, backpack.CELL * backpack.zoom, i * 0.06)
		i += 1

## Spawnt ein Flug-Overlay und laesst es in die Kiste gleiten.
func _fly_to_chest(entry: Dictionary, start_global: Vector2, start_cell_px: float, delay := 0.0) -> void:
	var fp: FlyingPiece = FLYING_PIECE.instantiate()
	fly_layer.add_child(fp)
	fp.setup(entry.kind, entry.tex, entry.base_cells, entry.cells, entry.rot, start_cell_px)
	fp.position = start_global - fly_layer.global_position

	var target := _chest_drop_point()
	var target_scale := float(W_CELL) / float(start_cell_px)
	var dur := 0.4
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(fp, "position", target - fly_layer.global_position, dur) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(delay)
	tw.tween_property(fp, "scale", Vector2(target_scale, target_scale), dur).set_delay(delay)
	tw.tween_property(fp, "modulate:a", 0.7, dur).set_delay(delay)
	tw.set_parallel(false)
	tw.tween_callback(_finish_fly.bind(entry, fp))

## Zielpunkt fuer die Flug-Animation (innerhalb der Kiste).
func _chest_drop_point() -> Vector2:
	return chest_panel.global_position + Vector2(40, 60)

## Abschluss eines Fluges: Overlay entfernen, Eintrag in die Kiste legen.
func _finish_fly(entry: Dictionary, fp: FlyingPiece) -> void:
	if is_instance_valid(fp):
		fp.queue_free()
	if entry.data == null:
		# Loser Stauraum -> neuer Kisten-Eintrag.
		chest_items.append(_new_instance(ItemDB.make_storage(entry.cells)))
	else:
		if not _has_uid(chest_items, entry.data.uid):
			chest_items.append(entry.data)
	_rebuild_chest()
