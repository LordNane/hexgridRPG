@abstract
class_name Condition extends Resource
## A yes/no question about the game state that gates content: POIs now; later shop stock and job
## unlocks. Each new kind of check is one small subclass.


## Whether the condition holds right now.
@abstract func is_met(session: GameSession) -> bool
