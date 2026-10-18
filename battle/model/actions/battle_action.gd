@abstract
class_name BattleAction extends RefCounted
## One command for the unit whose turn it is, such as moving or attacking. Give it to
## Battle.execute, which checks it and returns what happened. Each kind is a small subclass.

## The unit carrying it out.
var unit: BattleUnit


## Why the action can't be done right now, as a sentence for the player, or "".
@abstract func check(battle: Battle) -> String


## Carries the action out and returns what happened. Battle.execute calls it once [method check]
## passes.
@abstract func run(battle: Battle) -> Array[BattleEvent]
