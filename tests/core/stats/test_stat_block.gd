extends GutTest

var _base: StatBlock


func before_each() -> void:
	_base = StatBlock.new({Stat.Id.HP: 40, Stat.Id.ATTACK: 10, Stat.Id.SPEED: 6})


func test_with_no_modifiers_the_base_comes_out_unchanged() -> void:
	var stats := StatBlock.compute(_base, [])
	assert_true(stats.same_as(_base))
	assert_eq(stats.value(Stat.Id.ATTACK), 10)


func test_flat_amounts_add_up() -> void:
	var stats := StatBlock.compute(_base, [_mod(Stat.Id.ATTACK, 5), _mod(Stat.Id.ATTACK, -2)])
	assert_eq(stats.value(Stat.Id.ATTACK), 13)


func test_percentages_add_up_and_apply_after_flat_amounts() -> void:
	var stats := StatBlock.compute(_base, [
		_mod(Stat.Id.ATTACK, 10, StatModifier.Kind.PERCENT),
		_mod(Stat.Id.ATTACK, 2),
		_mod(Stat.Id.ATTACK, 40, StatModifier.Kind.PERCENT),
	])
	assert_eq(stats.value(Stat.Id.ATTACK), 18, "(10 + 2) × 150%")


func test_multipliers_stack_and_apply_last() -> void:
	var stats := StatBlock.compute(_base, [
		_mod(Stat.Id.HP, 0.5, StatModifier.Kind.MULTIPLY),
		_mod(Stat.Id.HP, 10, StatModifier.Kind.PERCENT),
		_mod(Stat.Id.HP, 0.5, StatModifier.Kind.MULTIPLY),
		_mod(Stat.Id.HP, 4),
	])
	assert_eq(stats.value(Stat.Id.HP), 12, "(40 + 4) × 110% × 0.25 = 12.1")


func test_results_round_to_whole_numbers_and_respect_minimums() -> void:
	var fractional := StatBlock.new({Stat.Id.HP: 10, Stat.Id.SPEED: 6.6})
	var stats := StatBlock.compute(fractional, [_mod(Stat.Id.HP, -50), _mod(Stat.Id.ATTACK, -3)])
	assert_eq(stats.value(Stat.Id.SPEED), 7)
	assert_eq(stats.value(Stat.Id.HP), 1, "HP never drops below 1")
	assert_eq(stats.value(Stat.Id.ATTACK), 0, "other stats never drop below 0")
	assert_eq(stats.exact(Stat.Id.SPEED), 7.0, "computed stats have no fractions")


func test_modifiers_only_touch_their_own_stat_and_change_nothing_given() -> void:
	var boost := _mod(Stat.Id.ATTACK, 5)
	var stats := StatBlock.compute(_base, [boost])
	assert_eq(stats.value(Stat.Id.SPEED), 6)
	assert_eq(_base.value(Stat.Id.ATTACK), 10, "the base is unchanged")
	assert_eq(boost.value, 5.0)


func test_survives_a_json_round_trip_keyed_by_stat_name() -> void:
	var own := StatBlock.new({Stat.Id.HP: 42.5, Stat.Id.MAGIC: 7.25})
	var data := own.to_dict()
	assert_eq(data["hp"], 42.5)
	var loaded := StatBlock.from_dict(JSON.parse_string(JSON.stringify(data)))
	assert_eq(loaded.exact(Stat.Id.HP), 42.5)
	assert_eq(loaded.exact(Stat.Id.MAGIC), 7.25)
	assert_eq(StatBlock.from_dict({"luck": 3, "magic": 2}).value(Stat.Id.MAGIC), 2, "unknown stats are ignored")


func test_modifiers_describe_themselves() -> void:
	assert_eq(_mod(Stat.Id.ATTACK, 5).describe(), "Attack +5")
	assert_eq(_mod(Stat.Id.SPEED, -1).describe(), "Speed -1")
	assert_eq(_mod(Stat.Id.DEFENSE, 10, StatModifier.Kind.PERCENT).describe(), "Defense +10%")
	assert_eq(_mod(Stat.Id.MOVE, 1.5, StatModifier.Kind.MULTIPLY).describe(), "Move ×1.5")


func test_stat_keys_round_trip() -> void:
	for stat: Stat.Id in Stat.all():
		assert_eq(Stat.from_key(Stat.key(stat)), stat)
	assert_eq(Stat.from_key("luck"), -1)


func _mod(stat: Stat.Id, value: float, kind: StatModifier.Kind = StatModifier.Kind.FLAT) -> StatModifier:
	return StatModifier.new(stat, value, kind)
