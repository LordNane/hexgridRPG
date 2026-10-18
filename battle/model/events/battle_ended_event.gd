class_name BattleEndedEvent extends BattleEvent
## The battle is over with [member result]: a victory or a defeat.

var result: BattleOutcome.Result


func _init(ending: BattleOutcome.Result) -> void:
	result = ending
