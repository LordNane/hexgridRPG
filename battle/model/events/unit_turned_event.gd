class_name UnitTurnedEvent extends BattleEvent
## [member unit] turned to face [member facing], an [enum Hex.Dir].

var unit: BattleUnit
var facing: int


func _init(turner: BattleUnit, faces: int) -> void:
	unit = turner
	facing = faces
