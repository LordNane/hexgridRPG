extends GutTest


func test_base_damage_weighs_attack_against_defense() -> void:
	var damage := DamageEffect.new()
	assert_eq(CombatMath.base_damage(_stats(10, 6), _stats(10, 6), damage), 12.0, "10 × 1.5 − 6 × 0.5")
	damage.power = 2.0
	assert_eq(CombatMath.base_damage(_stats(10, 6), _stats(10, 6), damage), 24.0)
	assert_eq(CombatMath.base_damage(_stats(1, 0), _stats(1, 50), damage), 1.0, "never below 1")


func test_magical_damage_uses_magic_and_resist() -> void:
	var damage := DamageEffect.new()
	damage.kind = DamageEffect.Kind.MAGICAL
	var caster := StatBlock.new({Stat.Id.MAGIC: 20, Stat.Id.ATTACK: 1})
	var target := StatBlock.new({Stat.Id.RESIST: 10, Stat.Id.DEFENSE: 99})
	assert_eq(CombatMath.base_damage(caster, target, damage), 25.0)


func test_rolls_stay_within_the_variance() -> void:
	var rng := SeededRng.new(3)
	var damage := DamageEffect.new()
	var seen: Dictionary[int, bool] = {}
	for _i: int in 200:
		var amount := CombatMath.damage(_stats(20, 0), _stats(0, 0), damage, rng)
		assert_between(amount, 27, 33, "30 give or take 10%")
		seen[amount] = true
	assert_gt(seen.size(), 3, "the rolls vary")


func _stats(attack: int, defense: int) -> StatBlock:
	return StatBlock.new({Stat.Id.ATTACK: attack, Stat.Id.DEFENSE: defense})
