class_name FacingState extends BattleState
## Choosing which way the active unit faces before its turn ends: arrow keys turn it, as does
## pointing at a hex; confirm ends the turn.

var _facing := 0


func enter(_message: Dictionary) -> void:
	_facing = mode.battle.active.facing
	_show()
	mode.hud.show_hint("Face which way?  (Esc: back)")


func exit() -> void:
	mode.view.clear_highlights()


func handle_input(event: InputEvent) -> void:
	var unit := mode.battle.active
	if event.is_action_pressed(&"cancel"):
		mode.view.unit_view(unit).face(unit.facing)
		transition_to(&"command")
		return
	if mode.confirms(event):
		transition_to(&"resolve", {"action": WaitAction.new(unit, _facing), "next": &"turn_start"})
		return
	for action: StringName in BattleMode.CURSOR_ACTIONS:
		if event.is_action_pressed(action):
			var toward := mode.view.projection.layout.neighbor_toward(unit.hex, BattleMode.CURSOR_ACTIONS[action])
			_facing = Hex.direction_to(unit.hex, toward)
			_show()
			return
	if event is InputEventMouseMotion:
		var hex := mode.view.hex_at(mode.view.get_local_mouse_position())
		if hex != CellPicker.NONE and hex != unit.hex:
			_facing = Hex.direction_to(unit.hex, hex)
			_show()


## Turns the unit's figure and highlights the hex it would face.
func _show() -> void:
	var unit := mode.battle.active
	mode.view.unit_view(unit).face(_facing)
	mode.view.clear_highlights()
	var faced: Array[Vector2i] = [Hex.neighbor(unit.hex, _facing)]
	mode.view.highlight(faced, BattleView.MOVE_COLOR)
	mode.set_cursor(unit.hex)
