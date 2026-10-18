class_name SelectTargetState extends BattleState
## Choosing what the active unit attacks: the hexes in its weapon's range are highlighted.

var _ability: AbilityDef


func enter(_message: Dictionary) -> void:
	var unit := mode.battle.active
	_ability = unit.character.attack_ability()
	mode.view.highlight(Targeting.hexes_in_range(mode.battle, unit, _ability, unit.hex), BattleView.TARGET_COLOR)
	mode.hud.show_hint("%s: attack what?  (Esc: back)" % _ability.display_name)


func exit() -> void:
	mode.view.clear_highlights()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		transition_to(&"command")
	elif mode.confirms(event):
		var action := AbilityAction.new(mode.battle.active, _ability, mode.cursor)
		var reason := mode.battle.check(action)
		if reason:
			mode.hud.show_hint(reason)
		else:
			transition_to(&"resolve", {"action": action, "next": &"command"})
	else:
		mode.move_cursor(event)
