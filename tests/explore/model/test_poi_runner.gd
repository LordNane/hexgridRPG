extends GutTest

var _session: GameSession
var _host: RecordingPoiHost
var _state: MapState


func before_each() -> void:
	_session = GameSession.new(1)
	_host = RecordingPoiHost.new()
	_state = _session.world.map_state(&"test")


func test_a_chest_gives_its_items_exactly_once() -> void:
	var chest := FakeContent.poi(&"chest", [FakeContent.give(FakeContent.item(&"potion"), 2)])
	chest.once = true
	await PoiRunner.run(chest, _context())
	await PoiRunner.run(chest, _context())
	assert_eq(_session.inventory.count_of(&"potion"), 2)
	var expected: Array[String] = ["Found Potion ×2."]
	assert_eq(_host.said, expected)
	assert_true(_state.is_used(Vector2i.ZERO))


func test_actions_run_in_order() -> void:
	var flag := SetFlagAction.new()
	flag.flag = &"blessed"
	var shrine := FakeContent.poi(&"shrine", [FakeContent.message("You kneel."), flag, FakeContent.message("You feel blessed.")])
	await PoiRunner.run(shrine, _context())
	var expected: Array[String] = ["You kneel.", "You feel blessed."]
	assert_eq(_host.said, expected)
	assert_true(_session.world.has_flag(&"blessed"))


func test_an_unmet_condition_explains_and_skips_the_actions() -> void:
	var stones := FakeContent.poi(&"stones", [FakeContent.give(FakeContent.item(&"ether"), 1)])
	stones.conditions = [FakeContent.flag_condition(&"blessed")]
	stones.unavailable_text = "The stones are silent."
	stones.once = true
	await PoiRunner.run(stones, _context())
	var expected: Array[String] = ["The stones are silent."]
	assert_eq(_host.said, expected)
	assert_eq(_session.inventory.count_of(&"ether"), 0)
	assert_false(_state.is_used(Vector2i.ZERO), "not used up while locked")

	_session.world.set_flag(&"blessed")
	await PoiRunner.run(stones, _context())
	assert_eq(_session.inventory.count_of(&"ether"), 1)


func test_a_chest_can_hold_gold() -> void:
	var loot := FakeContent.give(FakeContent.item(&"potion"), 1)
	loot.gold = 50
	await PoiRunner.run(FakeContent.poi(&"chest", [loot]), _context())
	assert_eq(_session.gold, 50)
	var expected: Array[String] = ["Found Potion ×1, 50 gold."]
	assert_eq(_host.said, expected)


func test_entering_a_map_waits_until_the_party_comes_back() -> void:
	_host.waits_in_maps = true
	var mouth := FakeContent.poi(&"mouth", [FakeContent.enter(FakeContent.map_def(&"cave"), &"mouth"),
			FakeContent.message("You blink in the daylight.")])
	PoiRunner.run(mouth, _context())
	var entered: Array[String] = ["cave:mouth"]
	assert_eq(_host.entered, entered)
	assert_true(_host.said.is_empty(), "the rest waits while the party is in the cave")
	_host.party_returned.emit()
	var expected: Array[String] = ["You blink in the daylight."]
	assert_eq(_host.said, expected)


func test_an_exit_asks_to_leave_the_map() -> void:
	await PoiRunner.run(FakeContent.poi(&"exit", [ExitMapAction.new()]), _context())
	assert_eq(_host.exits, 1)


func test_a_battle_poi_fights_its_encounter() -> void:
	var battle := StartBattleAction.new()
	battle.encounter = FakeContent.encounter(&"ambush", [])
	await PoiRunner.run(FakeContent.poi(&"camp", [battle]), _context())
	var fought: Array[String] = ["ambush"]
	assert_eq(_host.battles, fought)


func test_a_repeatable_poi_runs_every_time() -> void:
	var sign_post := FakeContent.poi(&"sign", [FakeContent.message("North: the Frost Reach.")])
	await PoiRunner.run(sign_post, _context())
	await PoiRunner.run(sign_post, _context())
	assert_eq(_host.said.size(), 2)


func _context() -> PoiContext:
	return PoiContext.new(_session, _state, Vector2i.ZERO, _host)
