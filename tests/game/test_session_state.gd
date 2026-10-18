extends GutTest


func test_inventory_adds_and_removes() -> void:
	var inventory := Inventory.new()
	inventory.add(&"potion", 2)
	inventory.add(&"potion")
	inventory.add(&"ether")
	assert_eq(inventory.count_of(&"potion"), 3)
	assert_true(inventory.remove(&"potion", 2))
	assert_eq(inventory.count_of(&"potion"), 1)
	assert_false(inventory.remove(&"potion", 5), "can't remove more than the party has")
	assert_true(inventory.remove(&"potion"))
	var expected: Array[StringName] = [&"ether"]
	assert_eq(inventory.item_ids(), expected)


func test_inventory_reports_changes() -> void:
	var inventory := Inventory.new()
	watch_signals(inventory)
	inventory.add(&"potion", 2)
	assert_signal_emitted_with_parameters(inventory, "changed", [&"potion", 2])


func test_flags_set_and_clear() -> void:
	var world := WorldState.new()
	watch_signals(world)
	world.set_flag(&"met_king")
	assert_true(world.has_flag(&"met_king"))
	world.set_flag(&"met_king", false)
	assert_false(world.has_flag(&"met_king"))
	assert_signal_emit_count(world, "flag_changed", 2)


func test_each_map_has_one_state() -> void:
	var world := WorldState.new()
	assert_same(world.map_state(&"overworld"), world.map_state(&"overworld"))
	assert_not_same(world.map_state(&"overworld"), world.map_state(&"cave"))


func test_gold_adds_up_and_reports_changes() -> void:
	var session := GameSession.new()
	watch_signals(session)
	session.add_gold(30)
	session.add_gold(12)
	assert_eq(session.gold, 42)
	assert_signal_emitted_with_parameters(session, "gold_changed", [42])


func test_leaving_a_map_returns_to_the_hex_the_party_entered_it_from() -> void:
	var session := GameSession.new()
	assert_null(session.location(), "nowhere before the journey starts")
	var overworld := session.enter_map(&"overworld", Vector2i(4, 2))
	overworld.hex = Vector2i(5, 2)
	session.enter_map(&"cave", Vector2i(0, 0)).hex = Vector2i(3, -1)
	assert_eq(session.location().map_id, &"cave")
	session.leave_map()
	assert_same(session.location(), overworld)
	assert_eq(session.location().hex, Vector2i(5, 2))


func test_session_survives_a_json_round_trip() -> void:
	var squire := FakeContent.job(&"squire", [], [FakeContent.ability(&"slash")])
	var session := GameSession.new(77)
	session.party.add(Character.new("Rin", squire, FakeContent.own_stats()))
	session.inventory.add(&"potion", 2)
	session.add_gold(150)
	session.enter_map(&"overworld", Vector2i(6, -3))
	session.enter_map(&"cave", Vector2i(-2, 7))
	session.world.set_flag(&"met_king")
	var state := session.world.map_state(&"overworld")
	state.explored[Vector2i(3, -2)] = true
	state.mark_used(Vector2i(-1, 4))
	session.advance_time(30.5)
	session.rng.randi_range(0, 100)

	var saved: Dictionary = JSON.parse_string(JSON.stringify(session.to_dict(), "", false))
	var loaded := GameSession.from_dict(saved, FakeContent.registry([squire]))

	assert_eq(loaded.party.size(), 1)
	assert_eq(loaded.party.members()[0].name, "Rin")
	assert_eq(loaded.party.members()[0].job, squire)
	assert_eq(loaded.inventory.count_of(&"potion"), 2)
	assert_eq(loaded.gold, 150)
	assert_eq(loaded.map_stack.size(), 2)
	assert_eq(loaded.map_stack[0].map_id, &"overworld")
	assert_eq(loaded.map_stack[0].hex, Vector2i(6, -3))
	assert_eq(loaded.location().map_id, &"cave")
	assert_eq(loaded.location().hex, Vector2i(-2, 7))
	assert_true(loaded.world.has_flag(&"met_king"))
	var loaded_state := loaded.world.map_state(&"overworld")
	assert_true(loaded_state.explored.has(Vector2i(3, -2)))
	assert_true(loaded_state.is_used(Vector2i(-1, 4)))
	assert_eq(loaded.hours, session.hours)
	assert_eq(loaded.day(), 2)
	for _i: int in 5:
		assert_eq(loaded.rng.randi_range(0, 1_000_000), session.rng.randi_range(0, 1_000_000), "random numbers continue identically")


func test_clock_reports_day_and_hour() -> void:
	var session := GameSession.new()
	assert_eq(session.day(), 1)
	assert_eq(session.hour_of_day(), 8)
	session.advance_time(17.5)
	assert_eq(session.day(), 2)
	assert_eq(session.hour_of_day(), 1)
