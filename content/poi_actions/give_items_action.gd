class_name GiveItemsAction extends PoiAction
## Gives the party items and gold and, unless [member silent], tells the player what was found.

## Each item and how many of it to give.
@export var items: Dictionary[ItemDef, int] = {}
@export var gold := 0
@export var silent := false


func run(ctx: PoiContext) -> void:
	var found := PackedStringArray()
	for item: ItemDef in items:
		ctx.session.inventory.add(item.id, items[item])
		found.append("%s ×%d" % [item.display_name, items[item]])
	if gold > 0:
		ctx.session.add_gold(gold)
		found.append("%d gold" % gold)
	if not silent and not found.is_empty():
		await ctx.say("Found " + ", ".join(found) + ".")
