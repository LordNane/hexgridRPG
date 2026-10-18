extends GutTest

var _squire: JobDef
var _hero: Character
var _sword: WeaponDef
var _bow: WeaponDef
var _shield: EquipmentDef
var _cap: EquipmentDef
var _ring: EquipmentDef


func before_each() -> void:
	_squire = FakeContent.job(&"squire", [&"sword", &"shield", &"hat"], [FakeContent.ability(&"slash")])
	_hero = Character.new("Hero", _squire, FakeContent.own_stats())
	_sword = FakeContent.weapon(&"sword", &"sword", 5)
	_bow = FakeContent.weapon(&"longbow", &"sword", 4, true)
	_shield = FakeContent.gear(&"buckler", EquipmentDef.Slot.SHIELD, &"shield")
	_cap = FakeContent.gear(&"cap", EquipmentDef.Slot.HEAD, &"hat")
	_ring = FakeContent.gear(&"ring", EquipmentDef.Slot.ACCESSORY)


func test_gear_the_job_lists_is_allowed() -> void:
	assert_eq(EquipRules.can_equip(_hero, _sword, EquipmentDef.Slot.WEAPON), "")
	assert_eq(EquipRules.can_equip(_hero, _cap, EquipmentDef.Slot.HEAD), "")


func test_untagged_gear_is_for_anyone() -> void:
	assert_eq(EquipRules.can_equip(_hero, _ring, EquipmentDef.Slot.ACCESSORY), "")


func test_taking_gear_off_is_always_allowed() -> void:
	assert_eq(EquipRules.can_equip(_hero, null, EquipmentDef.Slot.BODY), "")


func test_gear_goes_in_its_own_slot() -> void:
	assert_eq(EquipRules.can_equip(_hero, _cap, EquipmentDef.Slot.WEAPON), "The Cap goes in the Head slot.")


func test_gear_the_job_cant_use_is_refused_with_the_job_named() -> void:
	var rod := FakeContent.weapon(&"rod", &"rod")
	assert_eq(EquipRules.can_equip(_hero, rod, EquipmentDef.Slot.WEAPON), "Hero can't use the Rod as a Squire.")
	_hero = Character.new("Hero", FakeContent.job(&"archer"), FakeContent.own_stats())
	assert_string_contains(EquipRules.can_equip(_hero, rod, EquipmentDef.Slot.WEAPON), "as an Archer")


func test_no_shield_with_a_two_handed_weapon() -> void:
	_hero.equipment.set_item(EquipmentDef.Slot.WEAPON, _bow)
	assert_eq(EquipRules.can_equip(_hero, _shield, EquipmentDef.Slot.SHIELD), "The Longbow takes both hands.")


func test_a_two_handed_weapon_displaces_the_shield() -> void:
	var shield_slot: Array[EquipmentDef.Slot] = [EquipmentDef.Slot.SHIELD]
	assert_eq(EquipRules.displaced_slots(_bow, EquipmentDef.Slot.WEAPON), shield_slot)
	assert_true(EquipRules.displaced_slots(_sword, EquipmentDef.Slot.WEAPON).is_empty())
