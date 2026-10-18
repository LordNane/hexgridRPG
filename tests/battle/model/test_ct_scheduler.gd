extends GutTest

var _scheduler: CtScheduler


func before_each() -> void:
	_scheduler = CtScheduler.new()


func test_the_faster_unit_acts_first_and_more_often() -> void:
	var slow := _unit("Slow", 5)
	var fast := _unit("Fast", 10)
	var units: Array[BattleUnit] = [slow, fast]
	var turns: Array[String] = []
	for _i: int in 6:
		var unit := _scheduler.next(units)
		turns.append(unit.name)
		unit.moved = true
		unit.acted = true
		_scheduler.end_turn(unit)
	assert_eq(turns[0], "Fast")
	assert_eq(turns.count("Fast"), 4)
	assert_eq(turns.count("Slow"), 2)


func test_a_turn_costs_less_ct_for_doing_less() -> void:
	var unit := _unit("Hero", 6)
	unit.ct = 100
	_scheduler.end_turn(unit)
	assert_eq(unit.ct, 40, "neither moved nor acted")
	unit.ct = 110
	unit.moved = true
	_scheduler.end_turn(unit)
	assert_eq(unit.ct, 20, "moved: CT is capped at 100 first")
	unit.ct = 100
	unit.acted = true
	_scheduler.end_turn(unit)
	assert_eq(unit.ct, 0, "moved and acted")


func test_ties_go_to_the_unit_listed_first_and_the_fallen_never_act() -> void:
	var first := _unit("First", 6)
	var second := _unit("Second", 6)
	var fallen := _unit("Fallen", 20)
	fallen.character.hp = 0
	var units: Array[BattleUnit] = [fallen, first, second]
	assert_same(_scheduler.next(units), first)


func test_the_preview_matches_the_turns_that_follow() -> void:
	var units: Array[BattleUnit] = [_unit("A", 5), _unit("B", 7), _unit("C", 9)]
	var preview := _scheduler.preview(units, null, 8)
	var actual: Array[BattleUnit] = []
	for _i: int in 8:
		var unit := _scheduler.next(units)
		actual.append(unit)
		unit.moved = true
		unit.acted = true
		_scheduler.end_turn(unit)
	assert_eq(preview, actual)


func _unit(unit_name: String, speed: int) -> BattleUnit:
	var own := FakeContent.own_stats()
	own.set_value(Stat.Id.SPEED, speed)
	var character := Character.new(unit_name, FakeContent.job(&"brawler"), own)
	return BattleUnit.new(character, BattleUnit.Team.PARTY, Vector2i.ZERO, 0)
