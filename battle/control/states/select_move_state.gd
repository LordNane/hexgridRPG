class_name SelectMoveState extends BattleState
## Choosing where the active unit walks: the hexes it can reach are highlighted.

var _destinations: Array[Vector2i] = []


func enter(_message: Dictionary) -> void:
	var unit := mode.battle.active
	_destinations = BattleMovement.destinations(mode.battle, unit)
	_destinations.erase(unit.hex)
	mode.view.highlight(_destinations, BattleView.MOVE_COLOR)
	mode.hud.show_hint("Move where?  (Esc: back)")


func exit() -> void:
	mode.view.clear_highlights()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		transition_to(&"command")
	elif mode.confirms(event):
		if _destinations.has(mode.cursor):
			transition_to(&"resolve", {"action": MoveAction.new(mode.battle.active, mode.cursor), "next": &"command"})
		else:
			mode.hud.show_hint("%s can't get there." % mode.battle.active.name)
	else:
		mode.move_cursor(event)
