class_name PriorityQueue extends RefCounted
## A binary min-heap: [method pop] returns the item with the lowest priority.
## Equal priorities come out in the order they went in, which keeps searches deterministic.

var _items: Array = []
var _priorities := PackedFloat64Array()
var _insertion_order := PackedInt64Array()
var _next_insertion := 0


## How many items are waiting.
func size() -> int:
	return _items.size()


## Whether the queue is empty.
func is_empty() -> bool:
	return _items.is_empty()


## Adds [param item]; lower [param priority] values come out first.
func push(item: Variant, priority: float) -> void:
	_items.append(item)
	_priorities.append(priority)
	_insertion_order.append(_next_insertion)
	_next_insertion += 1
	_sift_up(_items.size() - 1)


## Removes and returns the lowest-priority item. The queue must not be empty.
func pop() -> Variant:
	var top: Variant = _items[0]
	var last := _items.size() - 1
	_swap(0, last)
	_items.resize(last)
	_priorities.resize(last)
	_insertion_order.resize(last)
	if last > 0:
		_sift_down(0)
	return top


## The lowest-priority item, without removing it. The queue must not be empty.
func peek() -> Variant:
	return _items[0]


func _sift_up(i: int) -> void:
	while i > 0:
		var parent := (i - 1) / 2
		if not _comes_before(i, parent):
			return
		_swap(i, parent)
		i = parent


func _sift_down(i: int) -> void:
	var count := _items.size()
	while true:
		var smallest := i
		var left := 2 * i + 1
		var right := left + 1
		if left < count and _comes_before(left, smallest):
			smallest = left
		if right < count and _comes_before(right, smallest):
			smallest = right
		if smallest == i:
			return
		_swap(i, smallest)
		i = smallest


## Whether the entry at heap index [param a] should come out before the one at [param b].
func _comes_before(a: int, b: int) -> bool:
	if _priorities[a] != _priorities[b]:
		return _priorities[a] < _priorities[b]
	return _insertion_order[a] < _insertion_order[b]


func _swap(a: int, b: int) -> void:
	var item: Variant = _items[a]
	_items[a] = _items[b]
	_items[b] = item
	var priority := _priorities[a]
	_priorities[a] = _priorities[b]
	_priorities[b] = priority
	var order := _insertion_order[a]
	_insertion_order[a] = _insertion_order[b]
	_insertion_order[b] = order
