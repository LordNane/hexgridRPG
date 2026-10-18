class_name PlaceholderAi
## Stand-in battle behavior until Phase 7's AiPlanner: attack the weakest foe in reach, walking to
## where one is in reach if need be, or else toward the nearest foe; then wait facing it. Used for
## enemies, and for the party when a battle plays itself.


## The next thing [param unit] does this turn. A WaitAction ends the turn.
static func next_action(battle: Battle, unit: BattleUnit) -> BattleAction:
	var attack := unit.character.attack_ability()
	if not unit.acted:
		var target := _weakest_target(battle, unit, attack, unit.hex)
		if target:
			return AbilityAction.new(unit, attack, target.hex)
	if not unit.moved:
		var destination := _best_destination(battle, unit, attack)
		if destination != unit.hex:
			return MoveAction.new(unit, destination)
	var nearest := _nearest_foe(battle, unit, unit.hex)
	var facing := unit.facing if nearest == null else Hex.direction_to(unit.hex, nearest.hex)
	return WaitAction.new(unit, facing)


## The foe with the least HP that [param attack] can hit from [param from], or null.
static func _weakest_target(battle: Battle, unit: BattleUnit, attack: AbilityDef, from: Vector2i) -> BattleUnit:
	var weakest: BattleUnit = null
	for foe: BattleUnit in _foes(battle, unit):
		if Targeting.can_target(battle, unit, attack, from, foe.hex).is_empty():
			if weakest == null or foe.character.hp < weakest.character.hp:
				weakest = foe
	return weakest


## Where to move: the closest spot to attack the weakest foe from if there's one in reach this
## turn, or else the spot nearest the nearest foe.
static func _best_destination(battle: Battle, unit: BattleUnit, attack: AbilityDef) -> Vector2i:
	if _foes(battle, unit).is_empty():
		return unit.hex
	var reach := BattleMovement.reach(battle, unit)
	var best := unit.hex
	var best_score := -INF
	for hex: Vector2i in BattleMovement.destinations(battle, unit):
		var target: BattleUnit = null
		if not unit.acted:
			target = _weakest_target(battle, unit, attack, hex)
		var score := 0.0
		if target:
			score = 1000.0 - target.character.hp
		else:
			score = -100.0 * Hex.distance(hex, _nearest_foe(battle, unit, hex).hex)
		# Shorter walks win ties; the hex order breaks any that remain, the same way every time.
		score -= reach.cost_to(hex) * 0.01
		if score > best_score or (score == best_score and _before(hex, best)):
			best = hex
			best_score = score
	return best


static func _nearest_foe(battle: Battle, unit: BattleUnit, from: Vector2i) -> BattleUnit:
	var nearest: BattleUnit = null
	for foe: BattleUnit in _foes(battle, unit):
		if nearest == null or Hex.distance(from, foe.hex) < Hex.distance(from, nearest.hex):
			nearest = foe
	return nearest


static func _foes(battle: Battle, unit: BattleUnit) -> Array[BattleUnit]:
	var foes: Array[BattleUnit] = []
	for other: BattleUnit in battle.units:
		if other.is_alive() and other.is_foe_of(unit):
			foes.append(other)
	return foes


static func _before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
