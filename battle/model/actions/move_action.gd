class_name MoveAction extends BattleAction
## Walks the unit to [member destination] along the cheapest way, once per turn. It ends facing
## the way it last stepped.

var destination: Vector2i


func _init(mover: BattleUnit, to: Vector2i) -> void:
	unit = mover
	destination = to


func check(battle: Battle) -> String:
	if unit.moved:
		return "%s has already moved this turn." % unit.name
	if destination == unit.hex:
		return "%s is already there." % unit.name
	if not BattleMovement.destinations(battle, unit).has(destination):
		return "%s can't get there." % unit.name
	return ""


func run(battle: Battle) -> Array[BattleEvent]:
	var path := BattleMovement.reach(battle, unit).path_to(destination)
	unit.hex = destination
	unit.moved = true
	unit.facing = Hex.direction_to(path[-2], path[-1])
	var events: Array[BattleEvent] = [UnitMovedEvent.new(unit, path)]
	return events
