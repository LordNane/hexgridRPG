class_name Targeting
## Where abilities can be aimed in battle, from an ability's TargetingDef: within its range in
## steps, and within its vertical reach. Phase 6 adds area shapes, line of sight and target filters.


## Every hex [param ability] could be aimed at by [param user] standing on [param from], whether or
## not anyone is there.
static func hexes_in_range(battle: Battle, user: BattleUnit, ability: AbilityDef, from: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var targeting := ability.targeting
	for distance: int in range(targeting.range_min, targeting.range_max + 1):
		for hex: Vector2i in Hex.ring(from, distance):
			if _reason_out_of_reach(battle, user, ability, from, hex).is_empty():
				found.append(hex)
	return found


## Why [param user], standing on [param from], can't aim [param ability] at [param hex], or "".
static func can_target(battle: Battle, user: BattleUnit, ability: AbilityDef, from: Vector2i, hex: Vector2i) -> String:
	var reason := _reason_out_of_reach(battle, user, ability, from, hex)
	if reason.is_empty() and units_hit(battle, hex).is_empty():
		reason = "There's nobody there."
	return reason


## The units [param hex] being targeted would hit: for now, whoever stands there.
static func units_hit(battle: Battle, hex: Vector2i) -> Array[BattleUnit]:
	var hit: Array[BattleUnit] = []
	var unit := battle.unit_at(hex)
	if unit:
		hit.append(unit)
	return hit


static func _reason_out_of_reach(battle: Battle, _user: BattleUnit, ability: AbilityDef, from: Vector2i, hex: Vector2i) -> String:
	var targeting := ability.targeting
	var distance := Hex.distance(from, hex)
	if not battle.map.has_hex(hex) or distance < targeting.range_min or distance > targeting.range_max:
		return "That's out of range."
	var climb := absi(battle.map.height_at(hex) - battle.map.height_at(from))
	if targeting.vertical_reach >= 0 and climb > targeting.vertical_reach:
		return "That's too far above or below."
	return ""
