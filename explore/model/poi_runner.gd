class_name PoiRunner
## Runs a POI when the party triggers it: honors its "once" rule and conditions, then runs its
## actions in order. A one-time POI is marked used only after all its actions finish.


static func run(poi: PoiDef, ctx: PoiContext) -> void:
	if poi.once and ctx.map_state.is_used(ctx.hex):
		return
	for condition: Condition in poi.conditions:
		if not condition.is_met(ctx.session):
			if poi.unavailable_text:
				await ctx.say(poi.unavailable_text)
			return
	for action: PoiAction in poi.actions:
		@warning_ignore("redundant_await")  # Actions may wait for the player; see PoiAction.run.
		await action.run(ctx)
	if poi.once:
		ctx.map_state.mark_used(ctx.hex)
