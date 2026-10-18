class_name StatBlock extends RefCounted
## A value for every stat. A character's final stats come from [method compute], the one function
## that combines what their level and job give them with every modifier from gear, equipped
## abilities and, in battle, statuses. Values may carry fractions, such as a character's own stats
## between level-ups, until compute rounds them.

var _values := PackedFloat64Array()


## [param values] maps Stat.Id to amounts. Stats it leaves out start at 0.
func _init(values: Dictionary = {}) -> void:
	_values.resize(Stat.Id.size())
	for stat: Variant in values:
		_values[stat] = float(values[stat])


## [param base] with [param modifiers] applied, in whole numbers and never below each stat's minimum.
## Each stat is (base + flat amounts) × (1 + percentages / 100) × multipliers, rounded. Changes neither.
static func compute(base: StatBlock, modifiers: Array[StatModifier]) -> StatBlock:
	var count := Stat.Id.size()
	var flat := PackedFloat64Array()
	flat.resize(count)
	var percent := PackedFloat64Array()
	percent.resize(count)
	var multiply := PackedFloat64Array()
	multiply.resize(count)
	multiply.fill(1.0)
	for modifier: StatModifier in modifiers:
		match modifier.kind:
			StatModifier.Kind.FLAT:
				flat[modifier.stat] += modifier.value
			StatModifier.Kind.PERCENT:
				percent[modifier.stat] += modifier.value
			StatModifier.Kind.MULTIPLY:
				multiply[modifier.stat] *= modifier.value
	var result := StatBlock.new()
	for stat: Stat.Id in Stat.all():
		var total := (base._values[stat] + flat[stat]) * (1.0 + percent[stat] / 100.0) * multiply[stat]
		result._values[stat] = maxi(roundi(total), Stat.minimum(stat))
	return result


## [param stat], rounded to a whole number.
func value(stat: Stat.Id) -> int:
	return roundi(_values[stat])


## [param stat], including any fraction.
func exact(stat: Stat.Id) -> float:
	return _values[stat]


func set_value(stat: Stat.Id, amount: float) -> void:
	_values[stat] = amount


func duplicate() -> StatBlock:
	var copy := StatBlock.new()
	copy._values = _values.duplicate()
	return copy


## Whether every stat rounds to the same whole number as in [param other].
func same_as(other: StatBlock) -> bool:
	for stat: Stat.Id in Stat.all():
		if value(stat) != other.value(stat):
			return false
	return true


## Keyed by [method Stat.key], so saves survive new stats being added.
func to_dict() -> Dictionary:
	var data := {}
	for stat: Stat.Id in Stat.all():
		data[Stat.key(stat)] = _values[stat]
	return data


static func from_dict(data: Dictionary) -> StatBlock:
	var block := StatBlock.new()
	for key: Variant in data:
		var stat := Stat.from_key(str(key))
		if stat >= 0:
			block._values[stat] = float(data[key])
	return block
