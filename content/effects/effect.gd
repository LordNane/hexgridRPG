@abstract
class_name Effect extends Resource
## One thing an ability does to each unit it hits, such as dealing damage. An ability lists its
## effects in order; each new kind of effect is one small subclass.


## Applies the effect from [param user] to [param target], changing [param battle], and returns
## what happened for the view to play.
@abstract func apply(battle: Battle, user: BattleUnit, target: BattleUnit) -> Array[BattleEvent]


## Data mistakes in this effect, for the content validator. The ability using it reports them.
func validate() -> PackedStringArray:
	return PackedStringArray()
