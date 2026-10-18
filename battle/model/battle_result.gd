class_name BattleResult extends RefCounted
## How a battle ended and what the party won, handed back to whoever started it.

var outcome := BattleOutcome.Result.NONE
var gold := 0
## Items won, as item id → count, in the order they dropped.
var items: Dictionary[StringName, int] = {}


## How [param battle] ended. After a victory, each fallen enemy's gold and drops are collected,
## drops rolled on the battle's RNG.
static func of(battle: Battle) -> BattleResult:
	var result := BattleResult.new()
	result.outcome = battle.result
	if not result.is_victory():
		return result
	for unit: BattleUnit in battle.units:
		if unit.source == null or unit.is_alive():
			continue
		result.gold += unit.source.gold
		for item: ItemDef in unit.source.drops:
			if battle.rng.chance(unit.source.drops[item]):
				result.items[item.id] = result.items.get(item.id, 0) + 1
	return result


func is_victory() -> bool:
	return outcome == BattleOutcome.Result.VICTORY


## Gives [param session] what the party won and, after a victory, fully restores every member,
## the fallen too, as in FF Tactics.
func apply_to(session: GameSession) -> void:
	if not is_victory():
		return
	if gold > 0:
		session.add_gold(gold)
	for item_id: StringName in items:
		session.inventory.add(item_id, items[item_id])
	for member: Character in session.party.members():
		member.restore()
