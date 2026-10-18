class_name AiTurnState extends BattleState
## The AI plays the active unit's turn, one action at a time, until it waits.

## Seconds before each of the AI's actions, so the player can follow them.
const THINK_SECONDS := 0.3


func enter(_message: Dictionary) -> void:
	_play_turn()


func _play_turn() -> void:
	var battle := mode.battle
	var unit := battle.active
	mode.hud.show_hint("%s's turn." % unit.name)
	while not battle.is_over():
		var action := PlaceholderAi.next_action(battle, unit)
		if action is MoveAction:
			mode.set_cursor((action as MoveAction).destination)
		elif action is AbilityAction:
			mode.set_cursor((action as AbilityAction).target)
		await mode.pause(THINK_SECONDS)
		await mode.play(battle.execute(action))
		if action is WaitAction:
			break
	transition_to(&"end" if battle.is_over() else &"turn_start")
