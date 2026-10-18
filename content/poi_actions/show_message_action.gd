class_name ShowMessageAction extends PoiAction
## Shows a message and waits for the player to dismiss it.

@export_multiline var text := ""


func run(ctx: PoiContext) -> void:
	await ctx.say(text)
