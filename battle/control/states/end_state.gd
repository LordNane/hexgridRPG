class_name EndState extends BattleState
## Shows how the battle ended and what was won, then hands the result back.


func enter(_message: Dictionary) -> void:
	_finish()


func _finish() -> void:
	mode.hud.show_hint("")
	mode.view.hide_cursor()
	var result := BattleResult.of(mode.battle)
	await mode.hud.show_result(result, ContentDB.registry, mode.instant)
	mode.finish(result)
