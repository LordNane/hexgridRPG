class_name CombatMath
## The game's combat formulas, kept in one place so battles, Phase 6's forecasts and Phase 7's AI
## all agree. Phase 6 adds hit chances, height, facing and elements.

## How far a damage roll strays either way: 0.1 is ±10%.
const DAMAGE_VARIANCE := 0.1


## The damage [param effect] deals, rolled on [param rng]: [method base_damage] give or take
## [constant DAMAGE_VARIANCE], at least 1.
static func damage(user_stats: StatBlock, target_stats: StatBlock, effect: DamageEffect, rng: SeededRng) -> int:
	var roll := rng.randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	return maxi(1, roundi(base_damage(user_stats, target_stats, effect) * roll))


## The damage before the random roll: (attack × 1.5 − defense × 0.5) × power, where attack and
## defense are Attack and Defense, or Magic and Resist for magical damage.
static func base_damage(user_stats: StatBlock, target_stats: StatBlock, effect: DamageEffect) -> float:
	var magical := effect.kind == DamageEffect.Kind.MAGICAL
	var attack := user_stats.value(Stat.Id.MAGIC if magical else Stat.Id.ATTACK)
	var defense := target_stats.value(Stat.Id.RESIST if magical else Stat.Id.DEFENSE)
	return maxf(1.0, (attack * 1.5 - defense * 0.5) * effect.power)
