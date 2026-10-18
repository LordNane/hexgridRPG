class_name DamageEffect extends Effect
## Deals damage: the user's Attack against the target's Defense, or for magical damage their Magic
## against Resist. CombatMath has the formula.

enum Kind { PHYSICAL, MAGICAL }

@export var kind := Kind.PHYSICAL
## Scales the damage: 1 for a plain weapon attack.
@export var power := 1.0


func apply(battle: Battle, user: BattleUnit, target: BattleUnit) -> Array[BattleEvent]:
	return battle.deal_damage(target, CombatMath.damage(user.stats(), target.stats(), self, battle.rng))


func validate() -> PackedStringArray:
	return PackedStringArray() if power > 0.0 else PackedStringArray(["a DamageEffect's power must be positive"])
