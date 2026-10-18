class_name FlagCondition extends Condition
## Holds while a story flag is set, or while it isn't when [member expect_set] is off.

@export var flag: StringName
@export var expect_set := true


func is_met(session: GameSession) -> bool:
	return session.world.has_flag(flag) == expect_set
