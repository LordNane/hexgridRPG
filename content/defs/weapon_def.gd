class_name WeaponDef extends EquipmentDef
## A weapon, worn in the Weapon slot. Its basic attack, the Attack command in battle, is an ability,
## so a bow can shoot from afar while a sword strikes up close.

## What the Attack command does with it.
@export var attack: AbilityDef
## Whether it takes both hands, leaving none for a shield.
@export var two_handed := false


func _init() -> void:
	slot = Slot.WEAPON


func validate() -> PackedStringArray:
	var problems := super()
	if slot != Slot.WEAPON:
		problems.append("is a weapon, so its slot must be Weapon")
	if attack == null:
		problems.append("has no attack ability")
	elif not attack.is_usable_in_battle():
		problems.append("its attack \"%s\" must be an action with targeting and effects" % attack.id)
	return problems
