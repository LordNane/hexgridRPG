extends GutTest
## The party menu's screens, driven the way a player would: highlight an option, choose it, and see
## the character and the screen change.

var _stack: ScreenStack
var _session: GameSession
var _content: ContentRegistry
var _hero: Character
var _squire: JobDef
var _mage: JobDef
var _fire: AbilityDef
var _sword: WeaponDef
var _rod: WeaponDef


func before_each() -> void:
	var slash := FakeContent.ability(&"slash")
	_fire = FakeContent.ability(&"fire")
	_squire = FakeContent.job(&"squire", [&"sword"], [slash])
	_mage = FakeContent.job(&"mage", [&"rod"], [_fire])
	_sword = FakeContent.weapon(&"sword", &"sword", 5)
	_rod = FakeContent.weapon(&"rod", &"rod")
	_content = FakeContent.registry([_squire, _mage, slash, _fire, _sword, _rod])
	_session = GameSession.new()
	_hero = Character.new("Hero", _squire, FakeContent.own_stats())
	_session.party.add(_hero)
	_session.inventory.add(&"sword")
	_session.inventory.add(&"rod")
	_stack = ScreenStack.new()
	add_child_autofree(_stack)


func after_each() -> void:
	await wait_process_frames(1, "let closed screens be deleted")


func test_the_party_screen_opens_a_members_screen() -> void:
	_stack.push(PartyScreen.new(_session, _content))
	assert_true(_option("Hero").has_focus(), "the first member is highlighted")
	_choose("Hero")
	assert_is(_stack.top(), CharacterScreen)
	_choose("Equip")
	assert_is(_stack.top(), EquipScreen)


func test_equipping_a_weapon_previews_then_updates_the_stats() -> void:
	_stack.push(EquipScreen.new(_hero, _session, _content))
	_choose("Weapon")
	_highlight("Sword")
	assert_eq(_stats_panel().shown_text(Stat.Id.ATTACK), "10 » 15", "the preview shows the new Attack")
	_choose("Sword")
	assert_eq(_hero.equipment.weapon(), _sword)
	assert_eq(_session.inventory.count_of(&"sword"), 0)
	assert_eq(_stats_panel().shown_text(Stat.Id.ATTACK), "15")
	assert_true(_option("Weapon").has_focus(), "back to choosing a slot")


func test_gear_the_job_cant_use_is_refused_with_the_reason_shown() -> void:
	_stack.push(EquipScreen.new(_hero, _session, _content))
	_choose("Weapon")
	_highlight("Rod")
	assert_eq(_stack.top().hint(), "Hero can't use the Rod as a Squire.")
	_choose("Rod")
	assert_null(_hero.equipment.weapon())
	assert_eq(_session.inventory.count_of(&"rod"), 1)
	assert_eq(_stack.top().hint(), "Hero can't use the Rod as a Squire.")


func test_cancel_steps_back_from_the_items_to_the_slots_then_closes() -> void:
	_stack.push(EquipScreen.new(_hero, _session, _content))
	_choose("Weapon")
	_stack.top().cancel()
	assert_eq(_stack.depth(), 1)
	assert_true(_option("Weapon").has_focus())
	_stack.top().cancel()
	assert_false(_stack.is_open())


func test_changing_jobs_updates_the_character_screen_below() -> void:
	_hero.equip(EquipmentDef.Slot.WEAPON, _sword, _session.inventory)
	_stack.push(CharacterScreen.new(_hero, _session, _content))
	_choose("Jobs")
	_highlight("Mage")
	assert_string_contains(_stack.top().hint(), "Changing takes off the Sword.")
	_choose("Mage")
	assert_eq(_hero.job, _mage)
	assert_eq(_session.inventory.count_of(&"sword"), 1)
	assert_eq(_stack.top().hint(), "Hero is now a Mage. The Sword went back to the inventory.")
	_stack.pop()
	assert_true(_shows_text(_stack.top(), "Mage  ·  Level 1"), "the character card followed the change")


func test_the_abilities_screen_sets_a_secondary_command() -> void:
	_hero.learn(_mage, _fire)
	_stack.push(AbilitiesScreen.new(_hero, _session))
	_choose("Second")
	_choose("Mage Arts")
	assert_eq(_hero.loadout.secondary, _mage)
	assert_true(_option("Second").has_focus())


func test_the_inventory_lists_items_by_kind_with_who_can_use_them() -> void:
	_stack.push(InventoryScreen.new(_session, _content))
	assert_true(_shows_text(_stack.top(), "Weapons"))
	_highlight("Rod")
	assert_true(_shows_text(_stack.top(), "Used by: Mage."))


## The option on the top screen labeled [param text].
func _option(text: String) -> Button:
	for node: Node in _stack.top().find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node
	fail_test("No option \"%s\" on %s." % [text, _stack.top()])
	return null


func _highlight(text: String) -> void:
	_option(text).grab_focus()


func _choose(text: String) -> void:
	var option := _option(text)
	option.grab_focus()
	option.pressed.emit()


func _stats_panel() -> StatsPanel:
	for node: Node in _stack.top().find_children("*", "GridContainer", true, false):
		if node is StatsPanel:
			return node
	return null


func _shows_text(screen: Node, text: String) -> bool:
	for node: Node in screen.find_children("*", "Label", true, false):
		if (node as Label).text == text:
			return true
	return false
