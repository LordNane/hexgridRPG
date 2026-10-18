class_name BattleState extends State
## One step of a battle turn in BattleMode, such as choosing where to move. States that play
## something run it as a coroutine from [method State.enter] and move on when it's done.

## The battle mode this state belongs to.
var mode: BattleMode
