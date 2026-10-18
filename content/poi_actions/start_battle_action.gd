class_name StartBattleAction extends PoiAction
## Starts a battle against [member encounter], such as an ambush or a guarded treasure. The POI's
## remaining actions run after a victory; a defeat ends the game.

@export var encounter: EncounterDef


func run(ctx: PoiContext) -> void:
	await ctx.start_battle(encounter)


func validate() -> PackedStringArray:
	return PackedStringArray() if encounter else PackedStringArray(["a StartBattleAction has no encounter"])
