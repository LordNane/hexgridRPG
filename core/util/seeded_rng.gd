class_name SeededRng extends RefCounted
## Deterministic randomness. Give each system its own SeededRng instead of using the global
## randi()/randf(), so any outcome can be reproduced from its seed: tests, bug reports and balance sims.

var _rng := RandomNumberGenerator.new()

## The generator's full internal state. Save it and set it back to resume the exact same sequence.
var state: int:
	get:
		return _rng.state
	set(value):
		_rng.state = value


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


## A random integer from [param from] to [param to], both included.
func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## A random float from 0.0 to 1.0.
func randf() -> float:
	return _rng.randf()


## A random float from [param from] to [param to].
func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## True with the given [param probability]: 0 never, 1 always.
func chance(probability: float) -> bool:
	if probability <= 0.0:
		return false
	if probability >= 1.0:
		return true
	return _rng.randf() < probability


## A random element of [param items], which must not be empty.
func pick(items: Array) -> Variant:
	return items[_rng.randi_range(0, items.size() - 1)]


## A random index into [param weights], each index chosen in proportion to its weight.
func pick_weighted(weights: PackedFloat32Array) -> int:
	return _rng.rand_weighted(weights)


## Shuffles [param items] in place. Use this instead of Array.shuffle(), which uses the global RNG.
func shuffle(items: Array) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swapped: Variant = items[i]
		items[i] = items[j]
		items[j] = swapped


## A new, independent generator seeded from this one, e.g. a battle's RNG from the session's.
func fork() -> SeededRng:
	return SeededRng.new(_rng.randi())
