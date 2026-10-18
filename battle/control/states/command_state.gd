class_name CommandState extends BattleState
## The command menu for the unit whose turn it is: Move, Attack or Wait. Once it has moved and
## acted, only facing is left.

const MOVE := &"move"
const ATTACK := &"attack"
const WAIT := &"wait"


func enter(_message: Dictionary) -> void:
	var battle := mode.battle
	var unit := battle.active
	if unit.moved and unit.acted:
		transition_to(&"facing")
		return
	mode.set_cursor(unit.hex)
	var can_move := not unit.moved and BattleMovement.destinations(battle, unit).size() > 1
	var options: Array[Array] = [["Move", MOVE, can_move], ["Attack", ATTACK, not unit.acted], ["Wait", WAIT, true]]
	mode.hud.show_commands(options)
	mode.hud.show_hint("%s's turn." % unit.name)
	mode.hud.command_chosen.connect(_on_chosen)


func exit() -> void:
	if mode.hud.command_chosen.is_connected(_on_chosen):
		mode.hud.command_chosen.disconnect(_on_chosen)
	mode.hud.hide_commands()


func _on_chosen(value: Variant) -> void:
	var unit := mode.battle.active
	match value:
		MOVE:
			if unit.moved:
				mode.hud.show_hint("%s has already moved this turn." % unit.name)
			else:
				transition_to(&"select_move")
		ATTACK:
			if unit.acted:
				mode.hud.show_hint("%s has already acted this turn." % unit.name)
			else:
				transition_to(&"select_target")
		WAIT:
			transition_to(&"facing")
