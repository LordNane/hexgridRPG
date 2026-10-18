class_name StartState extends BattleState
## Announces the encounter, then starts the first turn.


func enter(_message: Dictionary) -> void:
	_announce()


func _announce() -> void:
	mode.hud.show_turn_order(mode.battle.turn_order(BattleHud.TURNS_SHOWN))
	mode.set_cursor(mode.battle.map.party_spawns[0].hex)
	await mode.hud.announce(mode.request.encounter.display_name, mode.instant)
	transition_to(&"turn_start")
