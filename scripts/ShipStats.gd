class_name ShipStats
## Leitet aus Modulen + Systemen die Gefechtswerte eines Schiffs ab (FTL-artig).

static func compute(modules: Array, systems: Array, ship_name: String) -> Dictionary:
	var module_cells := 0
	for m in modules:
		module_cells += m.cells.size()

	var laser := 0
	var railgun := 0
	var rocket := 0
	var reactor := 0
	var shield := 0
	var sensor := 0
	var engine := 0
	var weapons: Array = []
	for s in systems:
		match String(s.data.name):
			"Laserkanone":
				laser += 1
				weapons.append({"name": "Laserkanone", "damage": 8, "charge_time": 4.0, "ammo": "ammo", "color": Color(0.95, 0.55, 0.35)})
			"Railgun":
				railgun += 1
				weapons.append({"name": "Railgun", "damage": 16, "charge_time": 9.0, "ammo": "ammo", "color": Color(0.6, 0.8, 1.0)})
			"Raketenwerfer":
				rocket += 1
				weapons.append({"name": "Raketenwerfer", "damage": 12, "charge_time": 7.0, "ammo": "rocket", "color": Color(0.95, 0.45, 0.42)})
			"Reaktor": reactor += 1
			"Deflektor": shield += 1
			"Sensor": sensor += 1
			"Triebwerk": engine += 1

	var hull_max := 60 + module_cells * 10
	var crew_max := 2 + modules.size() * 2
	var ammo_max := (laser + railgun) * 30
	var rockets_max := rocket * 5
	var produced := 6 + reactor * 10
	var evasion: int = min(60, engine * 8 + sensor * 3)

	var subsystems := [
		{"name": "Schilde", "demand": shield * 5, "color": Color(0.34, 0.72, 0.98)},
		{"name": "Waffen", "demand": laser * 3 + railgun * 4 + rocket * 3, "color": Color(0.95, 0.55, 0.35)},
		{"name": "Antrieb", "demand": engine * 4, "color": Color(0.95, 0.72, 0.32)},
		{"name": "Sensoren", "demand": sensor * 2, "color": Color(0.45, 0.85, 0.60)},
		{"name": "Leben", "demand": 4, "color": Color(0.40, 0.90, 0.80)},
	]
	var remaining := produced
	var demand_total := 0
	for s in subsystems:
		var alloc: int = min(s.demand, remaining)
		s["allocated"] = alloc
		remaining -= alloc
		demand_total += s.demand

	return {
		"name": ship_name,
		"hull": hull_max, "hull_max": hull_max,
		"ammo": ammo_max, "ammo_max": ammo_max,
		"rockets": rockets_max, "rockets_max": rockets_max,
		"crew": crew_max, "crew_max": crew_max,
		"power_produced": produced, "power_demand": demand_total,
		"shields": shield, "shield_block": shield * 4,
		"evasion": evasion,
		"weapons": weapons,
		"subsystems": subsystems,
	}

const _PREFIX := ["Pirat", "Drohne", "Korsar", "Marodeur", "Jaeger", "Waechter", "Renegat"]
const _SUFFIX := ["Sichel", "X-7", "Nemesis", "Vipernest", "Eisenfaust", "Schatten", "K-12", "Orion"]

static func random_enemy_name() -> String:
	return "%s «%s»" % [_PREFIX[randi() % _PREFIX.size()], _SUFFIX[randi() % _SUFFIX.size()]]
