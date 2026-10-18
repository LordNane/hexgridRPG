@abstract
class_name BattleOutcome extends Resource
## A way for a battle to end, such as defeating every enemy. Battle checks its outcomes after every
## action; the first one reached decides the battle. Each new win or lose condition is one small
## subclass.

enum Result { NONE, VICTORY, DEFEAT }


## [enum Result] VICTORY or DEFEAT if this outcome has been reached, else NONE.
@abstract func check(battle: Battle) -> Result
