class_name BattleMovement
## How units move in battle. Each step costs its terrain's battle_move_cost out of the unit's Move,
## and can't climb or drop more elevation levels than its Jump. Impassable terrain and blocking
## props can't be entered; foes block the way, while allies can be walked past but not stopped on.


## Every hex [param unit] can walk to this turn, with the way there.
static func reach(battle: Battle, unit: BattleUnit) -> ReachMap:
	return HexPathfinder.reachable(unit.hex, unit.stats().value(Stat.Id.MOVE), step_cost.bind(battle, unit))


## The hexes [param unit] can end a move on: in reach and free, plus where it stands.
static func destinations(battle: Battle, unit: BattleUnit) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for hex: Vector2i in reach(battle, unit).hexes():
		var occupant := battle.unit_at(hex)
		if occupant == null or occupant == unit:
			found.append(hex)
	return found


## The cost for [param unit] to step from [param from] onto its neighbor [param to], or INF if it can't.
static func step_cost(from: Vector2i, to: Vector2i, battle: Battle, unit: BattleUnit) -> float:
	var map := battle.map
	if not map.is_walkable(to):
		return INF
	if absi(map.height_at(to) - map.height_at(from)) > unit.stats().value(Stat.Id.JUMP):
		return INF
	var occupant := battle.unit_at(to)
	if occupant and occupant.is_foe_of(unit):
		return INF
	return map.terrain_at(to).battle_move_cost
