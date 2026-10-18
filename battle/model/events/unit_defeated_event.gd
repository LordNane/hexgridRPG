class_name UnitDefeatedEvent extends BattleEvent
## [member unit] fell. It no longer takes turns or holds its hex.

var unit: BattleUnit


func _init(fallen: BattleUnit) -> void:
	unit = fallen
