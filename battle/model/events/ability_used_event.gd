class_name AbilityUsedEvent extends BattleEvent
## [member user] used [member ability] on [member target]. Its effects follow as their own events.

var user: BattleUnit
var ability: AbilityDef
var target: Vector2i


func _init(by: BattleUnit, used: AbilityDef, at: Vector2i) -> void:
	user = by
	ability = used
	target = at
