class_name Inventory extends RefCounted
## The items the party carries, as a count per item id. Ids rather than Defs keep saves stable.

## Emitted whenever an item's count changes; [param count] is the new total.
signal changed(item_id: StringName, count: int)

var _counts: Dictionary[StringName, int] = {}


## Adds [param amount] of the item with [param item_id].
func add(item_id: StringName, amount: int = 1) -> void:
	assert(amount > 0, "Add a positive amount.")
	_counts[item_id] = count_of(item_id) + amount
	changed.emit(item_id, _counts[item_id])


## Removes [param amount] of the item if the party has that many; returns whether it did.
func remove(item_id: StringName, amount: int = 1) -> bool:
	var remaining := count_of(item_id) - amount
	if amount <= 0 or remaining < 0:
		return false
	if remaining == 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = remaining
	changed.emit(item_id, remaining)
	return true


## How many of the item the party has.
func count_of(item_id: StringName) -> int:
	return _counts.get(item_id, 0)


## The ids of every item the party has, in the order they were first acquired.
func item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_counts.keys())
	return ids


func to_dict() -> Dictionary:
	return {"counts": _counts.duplicate()}


static func from_dict(data: Dictionary) -> Inventory:
	var inventory := Inventory.new()
	var counts: Dictionary = data.get("counts", {})
	for item_id: Variant in counts:
		inventory._counts[StringName(item_id)] = int(counts[item_id])
	return inventory
