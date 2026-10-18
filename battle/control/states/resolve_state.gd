class_name ResolveState extends BattleState
## Carries out an action and plays what happened, then moves on: to the end if the battle is over,
## or else to the state named in the message's "next".


func enter(message: Dictionary) -> void:
	_resolve(message["action"], message["next"])


func _resolve(action: BattleAction, next: StringName) -> void:
	mode.hud.show_hint("")
	await mode.play(mode.battle.execute(action))
	transition_to(&"end" if mode.battle.is_over() else next)
