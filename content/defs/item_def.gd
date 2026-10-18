class_name ItemDef extends Def
## Anything the party can carry. Gear is an EquipmentDef (weapons a WeaponDef) and things used up
## are ConsumableDefs; a plain ItemDef is a key or keepsake that does nothing by itself.

## What it costs in shops, from Phase 8.
@export var price := 0


func validate() -> PackedStringArray:
	var problems := super()
	if price < 0:
		problems.append("price can't be negative")
	return problems
