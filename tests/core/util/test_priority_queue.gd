extends GutTest


func test_pops_lowest_priority_first() -> void:
	var queue := PriorityQueue.new()
	for priority: float in [5.0, 1.0, 4.0, 2.0, 3.0]:
		queue.push("p%d" % priority, priority)
	assert_eq(_drain(queue), ["p1", "p2", "p3", "p4", "p5"])


func test_equal_priorities_pop_in_insertion_order() -> void:
	var queue := PriorityQueue.new()
	for label: String in ["a", "b", "c", "d"]:
		queue.push(label, 1.0)
	queue.push("first", 0.0)
	assert_eq(_drain(queue), ["first", "a", "b", "c", "d"])


func test_random_pushes_come_out_sorted() -> void:
	var rng := SeededRng.new(42)
	var queue := PriorityQueue.new()
	var expected: Array = []
	for _i: int in 200:
		var priority := float(rng.randi_range(0, 50))
		expected.append(priority)
		queue.push(priority, priority)
	expected.sort()
	assert_eq(_drain(queue), expected)


func test_size_peek_and_empty() -> void:
	var queue := PriorityQueue.new()
	assert_true(queue.is_empty())
	queue.push("later", 2.0)
	queue.push("sooner", 1.0)
	assert_eq(queue.size(), 2)
	assert_eq(queue.peek(), "sooner")
	assert_eq(queue.size(), 2, "peek doesn't remove")
	queue.pop()
	queue.pop()
	assert_true(queue.is_empty())


func _drain(queue: PriorityQueue) -> Array:
	var out: Array = []
	while not queue.is_empty():
		out.append(queue.pop())
	return out
