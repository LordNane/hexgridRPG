extends GutTest
## Characters: stats from level, job, gear and abilities; the rules for changing them; and saving.


## Holds for characters at [member minimum] level or above, to check job unlocks see the character.
class LevelCondition extends Condition:
	var minimum := 1

	func is_met(_session: GameSession, character: Character = null) -> bool:
		return character != null and character.level >= minimum


var _slash: AbilityDef
var _counter: AbilityDef
var _equip_swords: AbilityDef
var _move_up: AbilityDef
var _fire: AbilityDef
var _magic_up: AbilityDef
var _squire: JobDef
var _mage: JobDef
var _sword: WeaponDef
var _greatsword: WeaponDef
var _rod: WeaponDef
var _shield: EquipmentDef
var _cap: EquipmentDef
var _ring: EquipmentDef
var _session: GameSession
var _inventory: Inventory
var _hero: Character


func before_each() -> void:
	_slash = FakeContent.ability(&"slash")
	_counter = FakeContent.ability(&"counter", AbilityDef.Kind.REACTION)
	_equip_swords = FakeContent.ability(&"equip_swords", AbilityDef.Kind.SUPPORT)
	_equip_swords.equip_tags = [&"sword"]
	_move_up = FakeContent.ability(&"move_up", AbilityDef.Kind.MOVEMENT, [FakeContent.modifier(Stat.Id.MOVE, 1)])
	_fire = FakeContent.ability(&"fire")
	_magic_up = FakeContent.ability(&"magic_up", AbilityDef.Kind.SUPPORT,
			[FakeContent.modifier(Stat.Id.MAGIC, 50, StatModifier.Kind.PERCENT)])

	_squire = FakeContent.job(&"squire", [&"sword", &"shield", &"hat"], [_slash, _counter, _equip_swords, _move_up])
	_squire.stat_multipliers = {Stat.Id.HP: 110, Stat.Id.ATTACK: 120}
	_squire.stat_growth = {Stat.Id.HP: 10.0, Stat.Id.ATTACK: 0.5}
	_squire.evasion = 10
	_mage = FakeContent.job(&"mage", [&"rod", &"hat"], [_fire, _magic_up])
	_mage.stat_multipliers = {Stat.Id.HP: 80, Stat.Id.MAGIC: 150}
	_mage.move = 3

	_sword = FakeContent.weapon(&"sword", &"sword", 5)
	_greatsword = FakeContent.weapon(&"greatsword", &"sword", 9, true)
	_rod = FakeContent.weapon(&"rod", &"rod")
	_shield = FakeContent.gear(&"buckler", EquipmentDef.Slot.SHIELD, &"shield", [FakeContent.modifier(Stat.Id.DEFENSE, 3)])
	_cap = FakeContent.gear(&"cap", EquipmentDef.Slot.HEAD, &"hat", [FakeContent.modifier(Stat.Id.HP, 6)])
	_ring = FakeContent.gear(&"ring", EquipmentDef.Slot.ACCESSORY, &"", [FakeContent.modifier(Stat.Id.SPEED, 50, StatModifier.Kind.PERCENT)])

	_session = GameSession.new()
	_inventory = _session.inventory
	for item: ItemDef in [_sword, _greatsword, _rod, _shield, _cap, _ring]:
		_inventory.add(item.id)
	_hero = Character.new("Hero", _squire, FakeContent.own_stats())


# --- Stats ------------------------------------------------------------------------------------


func test_stats_are_own_stats_scaled_by_the_job() -> void:
	var stats := _hero.stats()
	assert_eq(stats.value(Stat.Id.HP), 44, "40 × 110%")
	assert_eq(stats.value(Stat.Id.ATTACK), 12, "10 × 120%")
	assert_eq(stats.value(Stat.Id.MAGIC), 8, "unlisted stats stay at 100%")
	assert_eq(stats.value(Stat.Id.MOVE), 4, "Move comes from the job")
	assert_eq(stats.value(Stat.Id.EVASION), 10, "Evasion comes from the job")
	assert_eq(_hero.hp, 44, "starts at full HP")
	assert_eq(_hero.mp, 10)


func test_level_ups_add_the_jobs_growth_and_fractions_add_up() -> void:
	watch_signals(_hero)
	_hero.level_up()
	assert_eq(_hero.level, 2)
	assert_eq(_hero.own_stats().exact(Stat.Id.ATTACK), 10.5)
	assert_eq(_hero.stats().value(Stat.Id.HP), 55, "(40 + 10) × 110%")
	assert_eq(_hero.hp, 55, "HP rises with the maximum")
	_hero.level_up()
	assert_eq(_hero.own_stats().exact(Stat.Id.ATTACK), 11.0)
	assert_signal_emit_count(_hero, "changed", 2)


func test_hp_and_mp_stay_within_their_maximums() -> void:
	_hero.hp = 999
	assert_eq(_hero.hp, 44)
	_hero.mp = -3
	assert_eq(_hero.mp, 0)
	_hero.restore()
	assert_eq(_hero.mp, 10)


# --- Gear -------------------------------------------------------------------------------------


func test_equipping_gear_updates_stats_and_takes_it_from_the_inventory() -> void:
	watch_signals(_hero)
	assert_eq(_hero.equip(EquipmentDef.Slot.WEAPON, _sword, _inventory), "")
	assert_eq(_hero.equipment.weapon(), _sword)
	assert_eq(_hero.stats().value(Stat.Id.ATTACK), 17, "12 + 5")
	assert_eq(_inventory.count_of(&"sword"), 0)
	assert_signal_emitted(_hero, "changed")


func test_replaced_gear_goes_back_to_the_inventory() -> void:
	_hero.equip(EquipmentDef.Slot.WEAPON, _sword, _inventory)
	_hero.equip(EquipmentDef.Slot.WEAPON, _greatsword, _inventory)
	assert_eq(_inventory.count_of(&"sword"), 1)
	assert_eq(_hero.stats().value(Stat.Id.ATTACK), 21)


func test_gear_the_job_cant_use_is_refused_with_a_reason_and_nothing_changes() -> void:
	watch_signals(_hero)
	assert_eq(_hero.equip(EquipmentDef.Slot.WEAPON, _rod, _inventory), "Hero can't use the Rod as a Squire.")
	assert_null(_hero.equipment.weapon())
	assert_eq(_inventory.count_of(&"rod"), 1)
	assert_signal_not_emitted(_hero, "changed")


func test_gear_in_the_wrong_slot_or_not_carried_is_refused() -> void:
	assert_eq(_hero.equip(EquipmentDef.Slot.BODY, _cap, _inventory), "The Cap goes in the Head slot.")
	_inventory.remove(&"cap")
	assert_eq(_hero.equip(EquipmentDef.Slot.HEAD, _cap, _inventory), "There's no Cap in the inventory.")


func test_a_two_handed_weapon_sends_the_shield_back_and_then_refuses_one() -> void:
	_hero.equip(EquipmentDef.Slot.SHIELD, _shield, _inventory)
	_hero.equip(EquipmentDef.Slot.WEAPON, _greatsword, _inventory)
	assert_null(_hero.equipment.get_item(EquipmentDef.Slot.SHIELD))
	assert_eq(_inventory.count_of(&"buckler"), 1)
	assert_eq(_hero.equip(EquipmentDef.Slot.SHIELD, _shield, _inventory), "The Greatsword takes both hands.")


func test_unequipping_puts_gear_back_and_hp_stays_within_the_new_maximum() -> void:
	_hero.equip(EquipmentDef.Slot.HEAD, _cap, _inventory)
	_hero.restore()
	assert_eq(_hero.hp, 50)
	_hero.unequip(EquipmentDef.Slot.HEAD, _inventory)
	assert_eq(_inventory.count_of(&"cap"), 1)
	assert_eq(_hero.hp, 44)


func test_gear_previews_match_the_real_change_and_change_nothing() -> void:
	_hero.equip(EquipmentDef.Slot.SHIELD, _shield, _inventory)
	var before := _hero.stats()
	var preview := _hero.preview_equip(EquipmentDef.Slot.WEAPON, _greatsword)
	assert_eq(preview.value(Stat.Id.ATTACK), 21)
	assert_eq(preview.value(Stat.Id.DEFENSE), 6, "the shield comes off for a two-handed weapon")
	assert_true(_hero.stats().same_as(before), "previewing changes nothing")
	assert_eq(_hero.equipment.get_item(EquipmentDef.Slot.SHIELD), _shield)
	_hero.equip(EquipmentDef.Slot.WEAPON, _greatsword, _inventory)
	assert_true(_hero.stats().same_as(preview))
	assert_eq(_hero.preview_equip(EquipmentDef.Slot.WEAPON, null).value(Stat.Id.ATTACK), 12, "a null item previews an empty slot")


# --- Jobs -------------------------------------------------------------------------------------


func test_changing_jobs_rescales_stats_and_returns_gear_the_new_job_cant_use() -> void:
	for item: EquipmentDef in [_sword, _shield, _cap, _ring]:
		_hero.equip(item.slot, item, _inventory)
	var lost: Array[EquipmentDef] = [_sword, _shield]
	assert_eq(_hero.gear_lost_in_job(_mage), lost)
	var preview := _hero.preview_job(_mage)
	watch_signals(_hero)

	assert_eq(_hero.change_job(_mage, _session), "")

	assert_eq(_hero.job, _mage)
	assert_signal_emitted(_hero, "changed")
	assert_eq(_inventory.count_of(&"sword"), 1)
	assert_eq(_inventory.count_of(&"buckler"), 1)
	var kept: Array[EquipmentDef] = [_cap, _ring]
	assert_eq(_hero.equipment.items(), kept, "the hat and the untagged ring stay on")
	var stats := _hero.stats()
	assert_eq(stats.value(Stat.Id.HP), 38, "40 × 80% + 6")
	assert_eq(stats.value(Stat.Id.MAGIC), 12, "8 × 150%")
	assert_eq(stats.value(Stat.Id.MOVE), 3)
	assert_eq(stats.value(Stat.Id.SPEED), 9, "6 × 150% from the ring")
	assert_true(stats.same_as(preview), "the preview matched")
	assert_eq(_hero.hp, 38, "HP drops to the new maximum")


func test_job_changes_are_refused_while_locked_or_already_in_the_job() -> void:
	_mage.unlock_conditions = [FakeContent.flag_condition(&"met_the_mage")]
	_mage.unlock_hint = "Meet the mage first."
	assert_eq(_hero.change_job(_mage, _session), "Meet the mage first.")
	assert_eq(_hero.job, _squire)
	_mage.unlock_hint = ""
	assert_eq(_hero.can_change_job(_mage, _session), "Mage isn't unlocked yet.")
	_session.world.set_flag(&"met_the_mage")
	assert_eq(_hero.can_change_job(_mage, _session), "")
	assert_eq(_hero.can_change_job(_squire, _session), "Hero is already a Squire.")


func test_unlock_conditions_can_ask_about_the_character() -> void:
	var condition := LevelCondition.new()
	condition.minimum = 3
	_mage.unlock_conditions = [condition]
	assert_false(_mage.is_unlocked(_session, _hero))
	_hero.level_up()
	_hero.level_up()
	assert_true(_mage.is_unlocked(_session, _hero))


# --- Ability loadout -------------------------------------------------------------------------


func test_a_secondary_command_needs_actions_learned_in_another_job() -> void:
	assert_eq(_hero.set_secondary(_mage), "Hero hasn't learned any Mage Arts yet.")
	assert_eq(_hero.set_secondary(_squire), "Squire Arts is already Hero's main command.")
	_hero.learn(_mage, _fire)
	var options: Array[JobDef] = [_mage]
	assert_eq(_hero.secondary_options(), options)
	assert_eq(_hero.set_secondary(_mage), "")
	assert_eq(_hero.loadout.secondary, _mage)
	var learned: Array[AbilityDef] = [_fire]
	assert_eq(_hero.learned_actions(_mage), learned)


func test_changing_into_the_secondary_job_clears_the_secondary() -> void:
	_hero.learn(_mage, _fire)
	_hero.set_secondary(_mage)
	_hero.change_job(_mage, _session)
	assert_null(_hero.loadout.secondary)


func test_equipped_abilities_must_be_learned_and_their_modifiers_apply() -> void:
	assert_eq(_hero.equip_ability(_move_up, _inventory), "Hero hasn't learned Move Up.")
	assert_eq(_hero.equip_ability(_slash, _inventory), "Slash is used from a command, not equipped.")
	_hero.learn(_squire, _move_up)
	assert_eq(_hero.preview_ability(AbilityDef.Kind.MOVEMENT, _move_up).value(Stat.Id.MOVE), 5)
	assert_eq(_hero.equip_ability(_move_up, _inventory), "")
	assert_eq(_hero.loadout.get_ability(AbilityDef.Kind.MOVEMENT), _move_up)
	assert_eq(_hero.stats().value(Stat.Id.MOVE), 5)
	var movement: Array[AbilityDef] = [_move_up]
	assert_eq(_hero.learned_of_kind(AbilityDef.Kind.MOVEMENT), movement)
	_hero.unequip_ability(AbilityDef.Kind.MOVEMENT, _inventory)
	assert_eq(_hero.stats().value(Stat.Id.MOVE), 4)


func test_learned_abilities_carry_over_to_other_jobs() -> void:
	_hero.learn(_mage, _magic_up)
	_hero.equip_ability(_magic_up, _inventory)
	_hero.change_job(_mage, _session)
	assert_eq(_hero.stats().value(Stat.Id.MAGIC), 18, "8 × 150% × 150%")


func test_an_equip_ability_lets_other_jobs_use_gear_until_it_comes_off() -> void:
	_hero.learn(_squire, _equip_swords)
	_hero.change_job(_mage, _session)
	assert_ne(_hero.equip(EquipmentDef.Slot.WEAPON, _sword, _inventory), "", "mages can't use swords")
	_hero.equip_ability(_equip_swords, _inventory)
	assert_eq(_hero.equip(EquipmentDef.Slot.WEAPON, _sword, _inventory), "")
	var lost: Array[EquipmentDef] = [_sword]
	assert_eq(_hero.gear_lost_with_ability(AbilityDef.Kind.SUPPORT, null), lost)
	_hero.unequip_ability(AbilityDef.Kind.SUPPORT, _inventory)
	assert_null(_hero.equipment.weapon())
	assert_eq(_inventory.count_of(&"sword"), 1)


# --- Making and saving -----------------------------------------------------------------------


func test_from_def_levels_up_learns_and_wears_its_gear() -> void:
	var def := CharacterDef.new()
	def.id = &"rin"
	def.display_name = "Rin"
	def.job = _squire
	def.level = 3
	def.base_stats = {Stat.Id.HP: 40, Stat.Id.ATTACK: 10}
	def.equipment = [_sword, _cap]
	def.learned = [_slash, _fire]
	var rin := Character.from_def(def, FakeContent.registry([_squire, _mage]))
	assert_eq(rin.name, "Rin")
	assert_eq(rin.level, 3)
	assert_eq(rin.own_stats().exact(Stat.Id.HP), 60.0, "two levels of Squire growth")
	assert_eq(rin.equipment.weapon(), _sword)
	assert_true(rin.progress(_squire).knows(_slash))
	assert_true(rin.progress(_mage).knows(_fire), "learned from the job that teaches it")
	assert_eq(rin.hp, rin.max_hp())


func test_survives_a_json_round_trip() -> void:
	_hero.level_up()
	_hero.learn(_squire, _move_up)
	_hero.learn(_squire, _counter)
	_hero.learn(_mage, _fire)
	_hero.equip(EquipmentDef.Slot.WEAPON, _sword, _inventory)
	_hero.equip(EquipmentDef.Slot.HEAD, _cap, _inventory)
	_hero.equip_ability(_move_up, _inventory)
	_hero.equip_ability(_counter, _inventory)
	_hero.set_secondary(_mage)
	_hero.progress(_mage).jp = 120
	_hero.hp -= 7
	_hero.mp -= 4
	var content := FakeContent.registry([_squire, _mage, _sword, _cap, _slash, _counter, _move_up, _fire])

	var loaded := Character.from_dict(_json_round_trip(_hero.to_dict()), content)

	assert_eq(loaded.name, "Hero")
	assert_eq(loaded.level, 2)
	assert_eq(loaded.job, _squire)
	assert_eq(loaded.own_stats().exact(Stat.Id.ATTACK), 10.5)
	assert_true(loaded.stats().same_as(_hero.stats()))
	assert_eq(loaded.equipment.items(), _hero.equipment.items())
	assert_eq(loaded.loadout.abilities(), _hero.loadout.abilities())
	assert_eq(loaded.loadout.secondary, _mage)
	assert_eq(loaded.jobs(), _hero.jobs(), "jobs keep their order")
	assert_eq(loaded.progress(_squire).learned(), _hero.progress(_squire).learned())
	assert_eq(loaded.progress(_mage).jp, 120)
	assert_eq(loaded.hp, _hero.hp)
	assert_eq(loaded.mp, _hero.mp)


func test_loading_drops_content_that_no_longer_exists() -> void:
	_hero.learn(_squire, _counter)
	_hero.equip(EquipmentDef.Slot.HEAD, _cap, _inventory)
	_hero.equip(EquipmentDef.Slot.ACCESSORY, _ring, _inventory)
	var data := _json_round_trip(_hero.to_dict())
	var loaded := Character.from_dict(data, FakeContent.registry([_squire, _cap]))
	assert_push_warning("\"ring\"")
	assert_push_warning("\"counter\"")
	var kept: Array[EquipmentDef] = [_cap]
	assert_eq(loaded.equipment.items(), kept)
	assert_null(Character.from_dict(data, FakeContent.registry([])), "a character without a job can't load")
	assert_push_error("doesn't exist")


func test_a_party_survives_a_json_round_trip_in_order() -> void:
	var party := Party.new()
	watch_signals(party)
	party.add(_hero)
	party.add(Character.new("Sidekick", _mage, FakeContent.own_stats()))
	assert_signal_emit_count(party, "changed", 2)
	var loaded := Party.from_dict(_json_round_trip(party.to_dict()), FakeContent.registry([_squire, _mage]))
	assert_eq(loaded.size(), 2)
	assert_eq(loaded.members()[0].name, "Hero")
	assert_eq(loaded.members()[1].job, _mage)
	party.remove(_hero)
	assert_false(party.has(_hero))


## [param data] after being written as JSON and read back, the way SaveService does it.
func _json_round_trip(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data, "", false))
