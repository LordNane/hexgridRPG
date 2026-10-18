class_name ExitMapAction extends PoiAction
## Takes the party back to the map it entered this one from, onto the hex it entered from: the way
## out of a cave or a town. The party leaves once the POI's actions finish.


func run(ctx: PoiContext) -> void:
	ctx.exit_map()
