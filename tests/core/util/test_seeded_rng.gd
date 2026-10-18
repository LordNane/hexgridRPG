extends GutTest


func test_same_seed_gives_the_same_sequence() -> void:
	assert_eq(_sample(SeededRng.new(5)), _sample(SeededRng.new(5)))
	assert_ne(_sample(SeededRng.new(5)), _sample(SeededRng.new(6)))


func test_restoring_state_resumes_the_sequence() -> void:
	var rng := SeededRng.new(11)
	_sample(rng)
	var saved := rng.state
	var expected := _sample(rng)
	rng.state = saved
	assert_eq(_sample(rng), expected)


func test_shuffle_is_deterministic_and_keeps_every_element() -> void:
	var a := [1, 2, 3, 4, 5, 6, 7, 8]
	var b := a.duplicate()
	SeededRng.new(3).shuffle(a)
	SeededRng.new(3).shuffle(b)
	assert_eq(a, b)
	var sorted := a.duplicate()
	sorted.sort()
	assert_eq(sorted, [1, 2, 3, 4, 5, 6, 7, 8])


func test_chance_extremes() -> void:
	var rng := SeededRng.new(1)
	for _i: int in 100:
		assert_false(rng.chance(0.0))
		assert_true(rng.chance(1.0))


func test_pick_weighted_never_picks_a_zero_weight() -> void:
	var rng := SeededRng.new(8)
	for _i: int in 200:
		assert_ne(rng.pick_weighted(PackedFloat32Array([1.0, 0.0, 3.0])), 1)


func test_fork_is_reproducible() -> void:
	assert_eq(_sample(SeededRng.new(21).fork()), _sample(SeededRng.new(21).fork()))


func _sample(rng: SeededRng) -> Array[int]:
	var values: Array[int] = []
	for _i: int in 8:
		values.append(rng.randi_range(0, 1000))
	return values
