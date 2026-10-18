class_name UnitDamagedEvent extends BattleEvent
## [member unit] took [member amount] damage, leaving it with [member hp].

var unit: BattleUnit
var amount: int
var hp: int


func _init(hurt: BattleUnit, damage: int, hp_left: int) -> void:
	unit = hurt
	amount = damage
	hp = hp_left
