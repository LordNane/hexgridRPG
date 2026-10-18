class_name TurnEndedEvent extends BattleEvent
## [member unit]'s turn ended.

var unit: BattleUnit


func _init(whose: BattleUnit) -> void:
	unit = whose
