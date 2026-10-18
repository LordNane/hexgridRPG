class_name EnterMapAction extends PoiAction
## Takes the party into another map, such as a cave or a town, at one of its arrival points. The POI
## waits until the party leaves that map, then carries on with its remaining actions.

@export var map: MapDef
## The name of the EntryMarker on [member map] where the party arrives.
@export var entry: StringName = &"start"


func run(ctx: PoiContext) -> void:
	await ctx.enter_map(map, entry)


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if map == null:
		problems.append("an EnterMapAction has no map")
	if entry.is_empty():
		problems.append("an EnterMapAction has no entry")
	return problems
