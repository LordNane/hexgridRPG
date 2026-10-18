class_name SetFlagAction extends PoiAction
## Sets a story flag, or clears it when [member value] is off.

@export var flag: StringName
@export var value := true


func run(ctx: PoiContext) -> void:
	ctx.session.world.set_flag(flag, value)
