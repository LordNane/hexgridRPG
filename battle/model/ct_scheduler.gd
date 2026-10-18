class_name CtScheduler extends RefCounted
## Whose turn comes next, as in FF Tactics: each tick adds a unit's Speed to its charge time (CT),
## and a unit whose CT reaches [constant READY] takes a turn. Ending a turn spends CT, more if the
## unit both moved and acted, so idle units come back sooner.

const READY := 100
## CT a turn spends when the unit moved and acted, did one of the two, or did neither.
const COST_MOVED_AND_ACTED := 100
const COST_MOVED_OR_ACTED := 80
const COST_NEITHER := 60


## The living unit in [param units] whose turn is next, advancing everyone's CT until one is
## ready. The highest CT goes first; ties go to whoever is listed first. Null if nobody can act.
func next(units: Array[BattleUnit]) -> BattleUnit:
	var cts: Dictionary[BattleUnit, int] = {}
	for unit: BattleUnit in units:
		cts[unit] = unit.ct
	var chosen := _advance(cts, _actors(units))
	for unit: BattleUnit in cts:
		unit.ct = cts[unit]
	return chosen


## Spends [param unit]'s CT for the turn it just ended, by what it did.
func end_turn(unit: BattleUnit) -> void:
	var cost := COST_NEITHER
	if unit.moved and unit.acted:
		cost = COST_MOVED_AND_ACTED
	elif unit.moved or unit.acted:
		cost = COST_MOVED_OR_ACTED
	unit.ct = mini(unit.ct, READY) - cost


## The next [param count] turns, for the turn order display, starting with [param active] if a
## turn is under way. Its turn and every later one are assumed to spend the full CT. Changes nothing.
func preview(units: Array[BattleUnit], active: BattleUnit, count: int) -> Array[BattleUnit]:
	var turns: Array[BattleUnit] = []
	var cts: Dictionary[BattleUnit, int] = {}
	for unit: BattleUnit in units:
		cts[unit] = unit.ct
	if active:
		turns.append(active)
		cts[active] = mini(cts[active], READY) - COST_MOVED_AND_ACTED
	var actors := _actors(units)
	while turns.size() < count and not actors.is_empty():
		var unit := _advance(cts, actors)
		turns.append(unit)
		cts[unit] = mini(cts[unit], READY) - COST_MOVED_AND_ACTED
	return turns


## The units in [param units] that will ever act: alive, with some Speed.
static func _actors(units: Array[BattleUnit]) -> Array[BattleUnit]:
	var actors: Array[BattleUnit] = []
	for unit: BattleUnit in units:
		if unit.is_alive() and unit.stats().value(Stat.Id.SPEED) > 0:
			actors.append(unit)
	return actors


## Advances the CTs in [param cts] until one of [param actors] is ready, and returns it.
static func _advance(cts: Dictionary[BattleUnit, int], actors: Array[BattleUnit]) -> BattleUnit:
	if actors.is_empty():
		return null
	var ready := _most_ready(cts, actors)
	while ready == null:
		# Jump straight to the first tick at which someone is ready.
		var ticks := INF
		for unit: BattleUnit in actors:
			ticks = minf(ticks, ceilf(float(READY - cts[unit]) / unit.stats().value(Stat.Id.SPEED)))
		for unit: BattleUnit in actors:
			cts[unit] += int(ticks) * unit.stats().value(Stat.Id.SPEED)
		ready = _most_ready(cts, actors)
	return ready


## The ready unit with the highest CT, the first listed on ties, or null if none is ready.
static func _most_ready(cts: Dictionary[BattleUnit, int], actors: Array[BattleUnit]) -> BattleUnit:
	var ready: BattleUnit = null
	for unit: BattleUnit in actors:
		if cts[unit] >= READY and (ready == null or cts[unit] > cts[ready]):
			ready = unit
	return ready
