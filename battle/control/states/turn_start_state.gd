class_name TurnStartState extends BattleState
## Starts the next unit's turn, by charge time, and hands it to the player or the AI.


func enter(_message: Dictionary) -> void:
	_start()


func _start() -> void:
	var battle := mode.battle
	await mode.play(battle.start_turn())
	var unit := battle.active
	mode.hud.show_active(unit)
	mode.set_cursor(unit.hex)
	transition_to(&"ai_turn" if mode.ai_controls(unit) else &"command")
