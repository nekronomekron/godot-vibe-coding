class_name HudArt
## Liefert (gecachte) Nine-Patch-StyleBoxen fuer die HUD-Widgets.

static var _slot: StyleBoxTexture
static var _chip: StyleBoxTexture

static func _mk(path: String, margin: float) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(path)
	s.texture_margin_left = margin
	s.texture_margin_top = margin
	s.texture_margin_right = margin
	s.texture_margin_bottom = margin
	return s

## Vertiefter Track-Hintergrund fuer segmentierte Balken.
static func slot_box() -> StyleBoxTexture:
	if _slot == null:
		_slot = _mk("res://assets/hud/slot.svg", 11.0)
	return _slot

## Platten-Hintergrund fuer Ressourcen-Chips.
static func chip_box() -> StyleBoxTexture:
	if _chip == null:
		_chip = _mk("res://assets/hud/chip.svg", 12.0)
	return _chip
