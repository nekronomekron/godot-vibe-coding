extends Control
## Kampfbildschirm im FTL/Down-with-the-Ship-Stil.
## Links das eigene Schiff, rechts ein Zufallsgegner. Oben Huelle/Schilde/Ressourcen,
## unten Energieverteilung (Reaktor-Pips) und Waffen mit Echtzeit-Aufladung.

const HULL_COLOR := Color(0.36, 0.86, 0.45)

var player := {}
var enemy := {}
var p_weapons: Array = []   # Laufzeit: {name, damage, charge_time, ammo, color, charge}
var e_weapons: Array = []
var p_slots: Array = []      # WeaponSlot-Widgets (zu p_weapons)
var battle_over := false
var active := false           # Gefecht laeuft erst nach der Anflug-Animation
var _pm: Array
var _ps: Array
var _em: Array
var _es: Array

func _ready() -> void:
	var p_modules: Array
	var p_systems: Array
	if GameState.has_player():
		p_modules = GameState.player_modules
		p_systems = GameState.player_systems
	else:
		var g := ShipGen.generate_ship(5, 4)
		p_modules = g.modules
		p_systems = g.systems
	var e := ShipGen.generate_ship(randi_range(3, 6), randi_range(2, 5))

	%PlayerShip.setup(p_modules, p_systems)
	%EnemyShip.setup(e.modules, e.systems)
	_pm = p_modules
	_ps = p_systems
	_em = e.modules
	_es = e.systems

	player = ShipStats.compute(p_modules, p_systems, "Deine Fregatte")
	enemy = ShipStats.compute(e.modules, e.systems, ShipStats.random_enemy_name())

	%PlayerName.text = player.name
	%EnemyName.text = enemy.name
	%PlayerShields.setup(player.shields)
	%EnemyShields.setup(enemy.shields)
	%PowerTitle.text = "REAKTOR  %d/%d" % [player.power_produced, player.power_demand]

	p_weapons = _make_weapons(player)
	e_weapons = _make_weapons(enemy)

	_refresh_top()
	_fill_power(%PowerList, player)
	_build_weapon_slots()

	%FireButton.pressed.connect(_on_fire)
	%BackButton.pressed.connect(_on_back)

	if GameState.intro:
		GameState.intro = false
		_play_intro()
	else:
		active = true
		_log("Gegner gesichtet: %s." % enemy.name)
		_log("Systeme online. Waffen laden.")

func _make_weapons(st: Dictionary) -> Array:
	var out: Array = []
	for w in st.weapons:
		var d: Dictionary = w.duplicate()
		d["charge"] = 0.0
		out.append(d)
	return out

# --- Echtzeit-Aufladung --------------------------------------------------

func _process(delta: float) -> void:
	if not active or battle_over:
		return
	for w in p_weapons:
		if w.charge < 1.0:
			w.charge = min(1.0, w.charge + delta / w.charge_time)
	# Gegner feuert automatisch, sobald eine Waffe geladen ist.
	for w in e_weapons:
		w.charge += delta / w.charge_time
		if w.charge >= 1.0:
			w.charge = 0.0
			_enemy_fire(w)
			if battle_over:
				break
	_update_weapon_slots()
	_update_fire_button()

func _update_weapon_slots() -> void:
	for i in p_slots.size():
		var w: Dictionary = p_weapons[i]
		p_slots[i].set_charge(w.charge, w.charge >= 1.0, not _has_ammo(player, w))

func _update_fire_button() -> void:
	if battle_over:
		return
	var ready := false
	for w in p_weapons:
		if w.charge >= 1.0 and _has_ammo(player, w):
			ready = true
			break
	%FireButton.disabled = not ready

# --- Munition / Feuern ---------------------------------------------------

func _has_ammo(st: Dictionary, w: Dictionary) -> bool:
	if w.ammo == "rocket":
		return st.rockets > 0
	if w.ammo == "ammo":
		return st.ammo > 0
	return true

func _spend_ammo(st: Dictionary, w: Dictionary) -> void:
	if w.ammo == "rocket":
		st.rockets = max(0, st.rockets - 1)
	elif w.ammo == "ammo":
		st.ammo = max(0, st.ammo - 1)

func _on_fire() -> void:
	if battle_over:
		return
	var fired := 0
	var total := 0
	for w in p_weapons:
		if w.charge >= 1.0 and _has_ammo(player, w):
			w.charge = 0.0
			_spend_ammo(player, w)
			var dmg: int = max(1, int(w.damage) - enemy.shield_block)
			enemy.hull = max(0, enemy.hull - dmg)
			total += dmg
			fired += 1
			_shoot_fx(%PlayerShip, %EnemyShip, w)
	if fired == 0:
		_log("Keine Waffe bereit.")
		return
	_log("Salve (%d): %d Schaden an %s." % [fired, total, enemy.name])
	_refresh_top()
	if enemy.hull <= 0:
		_log(">> %s zerstoert. SIEG!" % enemy.name)
		_end_battle(true)

func _enemy_fire(w: Dictionary) -> void:
	if not _has_ammo(enemy, w):
		return
	_spend_ammo(enemy, w)
	var dmg: int = max(1, int(w.damage) - player.shield_block)
	player.hull = max(0, player.hull - dmg)
	_shoot_fx(%EnemyShip, %PlayerShip, w)
	_log("%s feuert %s: %d Schaden." % [enemy.name, w.name, dmg])
	_refresh_top()
	if player.hull <= 0:
		_log(">> Deine Fregatte zerstoert. NIEDERLAGE.")
		_end_battle(false)

func _end_battle(victory: bool) -> void:
	battle_over = true
	%FireButton.disabled = true
	%FireButton.text = "SIEG" if victory else "ZERSTOERT"

# --- HUD-Aufbau ----------------------------------------------------------

func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

func _ratio(a: int, b: int) -> float:
	return 0.0 if b <= 0 else clampf(float(a) / float(b), 0.0, 1.0)

func _refresh_top() -> void:
	%PlayerHull.setup("HUELLE", "%d/%d" % [player.hull, player.hull_max], _ratio(player.hull, player.hull_max), HULL_COLOR, 24)
	%EnemyHull.setup("HUELLE", "%d/%d" % [enemy.hull, enemy.hull_max], _ratio(enemy.hull, enemy.hull_max), HULL_COLOR, 24)
	_fill_resources(%ResourceList, player)

func _fill_resources(container: Node, st: Dictionary) -> void:
	_clear(container)
	_add_chip(container, "Munition", str(st.ammo), Color(0.95, 0.72, 0.35))
	_add_chip(container, "Raketen", str(st.rockets), Color(0.95, 0.50, 0.42))
	_add_chip(container, "Mannschaft", str(st.crew), Color(0.45, 0.70, 0.95))
	_add_chip(container, "Energie", str(st.power_produced), Color(0.45, 0.9, 0.6))
	_add_chip(container, "Ausweichen", "%d%%" % st.evasion, Color(0.5, 0.85, 0.85))

func _add_chip(container: Node, label: String, value: String, accent: Color) -> void:
	var chip := ResourceChip.new()
	container.add_child(chip)
	chip.setup(label, value, accent)

func _fill_power(container: Node, st: Dictionary) -> void:
	_clear(container)
	for sub in st.subsystems:
		var col := PowerColumn.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(col)
		col.setup(sub.name, sub.allocated, sub.demand, sub.color)

func _build_weapon_slots() -> void:
	_clear(%WeaponList)
	p_slots.clear()
	if p_weapons.is_empty():
		var lbl := Label.new()
		lbl.text = "Keine Waffensysteme verbaut."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.66, 0.72))
		%WeaponList.add_child(lbl)
		return
	for w in p_weapons:
		var slot := WeaponSlot.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%WeaponList.add_child(slot)
		slot.setup(w.name, w.color)
		p_slots.append(slot)

## Spawnt einen Schuss-Effekt vom Angreifer- zum Ziel-Schiff.
func _shoot_fx(from_ship: Control, to_ship: Control, w: Dictionary) -> void:
	var origin: Vector2 = from_ship.get_global_rect().get_center() - %Fx.global_position
	var target: Vector2 = to_ship.get_global_rect().get_center() - %Fx.global_position
	target += Vector2(randf_range(-26, 26), randf_range(-26, 26))
	%Fx.fire(origin, target, w.color, String(w.name) == "Raketenwerfer")

func _log(line: String) -> void:
	%Log.append_text(line + "\n")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# --- Anflug-Animation ----------------------------------------------------

func _play_intro() -> void:
	# HUD unsichtbar halten, aber Layout berechnen lassen (fuer exakte Zielpositionen).
	$Margin.modulate = Color(1, 1, 1, 0)
	await get_tree().process_frame
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	var pr: Rect2 = (get_node("%PlayerShip") as Control).get_global_rect()
	var er: Rect2 = (get_node("%EnemyShip") as Control).get_global_rect()

	var cine := Control.new()
	cine.set_anchors_preset(Control.PRESET_FULL_RECT)
	cine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cine)

	# Cinematic-Schiffe exakt in Groesse/Hoehe der HUD-Schiffe -> nahtloser Uebergang.
	var cp := ShipView.new()
	cp.setup(_pm, _ps)
	cp.size = pr.size
	cp.position = Vector2(-pr.size.x - 80.0, pr.position.y) # links ausserhalb, gleiche Hoehe
	cine.add_child(cp)
	var ce := ShipView.new()
	ce.setup(_em, _es)
	ce.size = er.size
	ce.position = Vector2(vp.x + 80.0, er.position.y) # rechts ausserhalb, gleiche Hoehe
	cine.add_child(ce)

	var tw := create_tween()
	# Spieler fliegt von links, kurz darauf der Gegner von rechts – jeweils exakt auf
	# ihre HUD-Position, sodass beim Einblenden kein Sprung entsteht.
	tw.tween_property(cp, "position:x", pr.position.x, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(ce, "position:x", er.position.x, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.35)
	# Nahtloser Crossfade: HUD blendet an gleicher Stelle ein, Cinematic aus.
	tw.chain().tween_property($Margin, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(cine, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(_finish_intro.bind(cine))

func _finish_intro(cine: Node) -> void:
	cine.queue_free()
	$Margin.modulate = Color(1, 1, 1, 1)
	active = true
	_log("Gegner gesichtet: %s." % enemy.name)
	_log("Systeme online. Gefecht beginnt!")
