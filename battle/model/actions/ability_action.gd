class_name AbilityAction extends BattleAction
## Uses [member ability] on [member target], once per turn: pays its MP, turns toward the target and
## applies its effects to each unit hit.

var ability: AbilityDef
var target: Vector2i


func _init(user: BattleUnit, used: AbilityDef, at: Vector2i) -> void:
	unit = user
	ability = used
	target = at


func check(battle: Battle) -> String:
	if unit.acted:
		return "%s has already acted this turn." % unit.name
	if not ability.is_usable_in_battle():
		return "%s can't be used in battle yet." % ability.display_name
	if unit.character.mp < ability.mp_cost:
		return "%s needs %d MP." % [ability.display_name, ability.mp_cost]
	return Targeting.can_target(battle, unit, ability, unit.hex, target)


func run(battle: Battle) -> Array[BattleEvent]:
	unit.character.mp -= ability.mp_cost
	unit.acted = true
	if target != unit.hex:
		unit.facing = Hex.direction_to(unit.hex, target)
	var events: Array[BattleEvent] = [AbilityUsedEvent.new(unit, ability, target)]
	for hit: BattleUnit in Targeting.units_hit(battle, target):
		for effect: Effect in ability.effects:
			if hit.is_alive():
				events.append_array(effect.apply(battle, unit, hit))
	return events
