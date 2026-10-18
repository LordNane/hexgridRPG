class_name UnitMovedEvent extends BattleEvent
## [member unit] walked [member path], which starts where it stood.

var unit: BattleUnit
var path: Array[Vector2i]


func _init(mover: BattleUnit, route: Array[Vector2i]) -> void:
	unit = mover
	path = route
