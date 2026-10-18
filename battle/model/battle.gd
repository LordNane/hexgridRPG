class_name Battle extends RefCounted
## One battle's rules: the map, the units on it, whose turn it is, its randomness and how it can
## end. BattleMode presents it; this class decides, without any nodes.
##
## Each turn: [method start_turn], then actions for the active unit through [method execute] (a
## move, an ability, and a WaitAction to finish). Every call returns the events that happened, for
## [code]await view.play(events)[/code]. Once an outcome is reached, [member result] says how it ended.

var map: BattleMap
## Everyone in the battle, fallen units included: the party first, then the enemies.
var units: Array[BattleUnit]
var scheduler := CtScheduler.new()
var rng: SeededRng
## How the battle can end. The first one reached decides it.
var outcomes: Array[BattleOutcome]
## Whose turn it is, or null between turns.
var active: BattleUnit
## NONE while the battle goes on, then VICTORY or DEFEAT.
var result := BattleOutcome.Result.NONE


## [param win_lose] defaults to defeating every enemy or losing the whole party.
func _init(battle_map: BattleMap, fighters: Array[BattleUnit], seeded_rng: SeededRng, win_lose: Array[BattleOutcome] = []) -> void:
	map = battle_map
	units = fighters
	rng = seeded_rng
	outcomes = win_lose
	if outcomes.is_empty():
		outcomes = [DefeatAllEnemies.new(), PartyDefeated.new()]


func is_over() -> bool:
	return result != BattleOutcome.Result.NONE


## Starts the next unit's turn, by charge time.
func start_turn() -> Array[BattleEvent]:
	assert(active == null and not is_over(), "Finish the current turn first, and only while the battle goes on.")
	active = scheduler.next(units)
	active.moved = false
	active.acted = false
	var events: Array[BattleEvent] = [TurnStartedEvent.new(active)]
	return events


## Why [param action] can't be carried out now, as a sentence for the player, or "".
func check(action: BattleAction) -> String:
	if is_over():
		return "The battle is over."
	if action.unit != active:
		return "It isn't %s's turn." % action.unit.name
	return action.check(self)


## Carries out [param action], which must pass [method check], and returns what happened. Ends the
## battle if that reached an outcome.
func execute(action: BattleAction) -> Array[BattleEvent]:
	var reason := check(action)
	assert(reason.is_empty(), reason)
	var events := action.run(self)
	for outcome: BattleOutcome in outcomes:
		var reached := outcome.check(self)
		if reached != BattleOutcome.Result.NONE:
			result = reached
			active = null
			events.append(BattleEndedEvent.new(result))
			break
	return events


## Ends the active unit's turn, spending its charge time. Called by WaitAction.
func end_turn() -> void:
	scheduler.end_turn(active)
	active = null


## The living unit on [param hex], or null.
func unit_at(hex: Vector2i) -> BattleUnit:
	for unit: BattleUnit in units:
		if unit.hex == hex and unit.is_alive():
			return unit
	return null


## The living units of [param team].
func living(team: BattleUnit.Team) -> Array[BattleUnit]:
	var found: Array[BattleUnit] = []
	for unit: BattleUnit in units:
		if unit.team == team and unit.is_alive():
			found.append(unit)
	return found


## Takes [param amount] HP from [param target] and returns what happened, including its fall.
## Effects call this.
func deal_damage(target: BattleUnit, amount: int) -> Array[BattleEvent]:
	target.character.hp -= amount
	var events: Array[BattleEvent] = [UnitDamagedEvent.new(target, amount, target.character.hp)]
	if not target.is_alive():
		events.append(UnitDefeatedEvent.new(target))
	return events


## The next [param count] turns, for the turn order display.
func turn_order(count: int) -> Array[BattleUnit]:
	return scheduler.preview(units, active, count)
