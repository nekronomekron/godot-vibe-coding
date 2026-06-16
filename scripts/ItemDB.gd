class_name ItemDB
## Vorlagen-Datenbank fuer Items und Stauraum.
## Ein Item ist ein Dictionary: { kind, name, cells, color, tex, uid? }

enum Kind { STORAGE, ITEM }

const STORAGE_COLOR := Color(0.45, 0.38, 0.28)

# Texturen werden einmalig geladen und gecached.
static var _cache := {}

static func _tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

static func storage_tex() -> Texture2D:
	return _tex("res://assets/storage_cell.svg")

## Modul-Vorlage (Schiffsraum) aus Zellen (mit Tile-Textur).
static func make_storage(cells: Array) -> Dictionary:
	return {"kind": Kind.STORAGE, "name": "Modul", "cells": cells, "color": STORAGE_COLOR, "tex": storage_tex()}

static func _item(name: String, cells: Array, path: String) -> Dictionary:
	return {"kind": Kind.ITEM, "name": name, "cells": cells, "color": Color.WHITE, "tex": _tex(path)}

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
		_item("Laserkanone", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], "res://assets/items/laserkanone.svg"),
		_item("Reaktor", [Vector2i(0, 0)], "res://assets/items/reaktor.svg"),
		_item("Deflektor", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], "res://assets/items/deflektor.svg"),
		_item("Raketenwerfer", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], "res://assets/items/raketenwerfer.svg"),
		_item("Sensor", [Vector2i(0, 0), Vector2i(0, 1)], "res://assets/items/sensor.svg"),
		_item("Railgun", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], "res://assets/items/railgun.svg"),
		_item("Triebwerk", [Vector2i(0, 0), Vector2i(1, 0)], "res://assets/items/triebwerk.svg"),
	]

## Zufaelliges Angebot fuer den Haendler (Mischung aus Stauraum und Items).
static func random_offer(count: int) -> Array:
	var pool := storage_templates() + item_templates()
	var out: Array = []
	for i in count:
		out.append(pool[randi() % pool.size()].duplicate(true))
	return out
