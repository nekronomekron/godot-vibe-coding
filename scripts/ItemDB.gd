class_name ItemDB
## Vorlagen-Datenbank fuer Items und Stauraum.
## Ein Item ist ein Dictionary: { kind, name, cells, color, tex, uid? }

enum Kind { STORAGE, ITEM }

const STORAGE_COLOR := Color(0.45, 0.38, 0.28)

# Texturen werden einmalig geladen und gecached.
static var _cache := {}

static func _res(path: String) -> Resource:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

static func _tex(path: String) -> Texture2D:
	return _res(path) as Texture2D

static func storage_tex() -> Texture2D:
	return _tex("res://assets/storage_cell.svg")

## Modul-Vorlage (Schiffsraum) aus Zellen (mit Tile-Textur).
static func make_storage(cells: Array) -> Dictionary:
	return {"kind": Kind.STORAGE, "name": "Modul", "cells": cells, "color": STORAGE_COLOR, "tex": storage_tex()}

static func _item(name: String, cells: Array, path: String) -> Dictionary:
	return {"kind": Kind.ITEM, "name": name, "cells": cells, "color": Color.WHITE, "tex": _tex(path)}

## Waffe mit animiertem SpriteFrames (fuer AnimatedSprite2D in der Schiffsansicht).
static func _weapon(name: String, cells: Array, path: String, frames_path: String) -> Dictionary:
	var d := _item(name, cells, path)
	d["frames"] = _res(frames_path)
	return d

## Stauraum-Formen (erweitern den Rucksack).
static func storage_templates() -> Array:
	return [
		make_storage([Vector2i(0, 0), Vector2i(1, 0)]),
		make_storage([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]),
		make_storage([Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]),
		make_storage([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]),
		make_storage([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]),
	]

## Schiffssysteme (muessen in einem Modul platziert werden).
static func item_templates() -> Array:
	return [
		_weapon("Laserkanone", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], "res://assets/items/laserkanone.svg", "res://assets/items/laserkanone_frames.tres"),
		_item("Reaktor", [Vector2i(0, 0)], "res://assets/items/reaktor.svg"),
		_item("Deflektor", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], "res://assets/items/deflektor.svg"),
		_weapon("Raketenwerfer", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], "res://assets/items/raketenwerfer.svg", "res://assets/items/raketenwerfer_frames.tres"),
		_item("Sensor", [Vector2i(0, 0), Vector2i(0, 1)], "res://assets/items/sensor.svg"),
		_weapon("Railgun", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], "res://assets/items/railgun.svg", "res://assets/items/railgun_frames.tres"),
		_item("Triebwerk", [Vector2i(0, 0), Vector2i(1, 0)], "res://assets/items/triebwerk.svg"),
	]

## Zufaelliges Angebot fuer den Haendler (Mischung aus Stauraum und Items).
static func random_offer(count: int) -> Array:
	var pool := storage_templates() + item_templates()
	var out: Array = []
	for i in count:
		out.append(pool[randi() % pool.size()].duplicate(true))
	return out
