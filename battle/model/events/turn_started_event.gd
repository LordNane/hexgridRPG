class_name TurnStartedEvent extends BattleEvent
## [member unit]'s turn began.

var unit: BattleUnit


func _init(whose: BattleUnit) -> void:
	unit = whose
