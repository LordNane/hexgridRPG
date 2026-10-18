class_name WaitAction extends BattleAction
## Ends the unit's turn facing [member facing], an [enum Hex.Dir]. What the turn costs in charge
## time depends on whether it moved and acted.

var facing: int


func _init(waiter: BattleUnit, faces: int) -> void:
	unit = waiter
	facing = faces


func check(_battle: Battle) -> String:
	return "" if facing >= 0 and facing < Hex.DIR_COUNT else "That isn't a direction."


func run(battle: Battle) -> Array[BattleEvent]:
	unit.facing = facing
	battle.end_turn()
	var events: Array[BattleEvent] = [UnitTurnedEvent.new(unit, facing), TurnEndedEvent.new(unit)]
	return events
