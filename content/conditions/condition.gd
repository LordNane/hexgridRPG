@abstract
class_name Condition extends Resource
## A yes/no question about the game state that gates content: POIs and job unlocks now; later shop
## stock. Each new kind of check is one small subclass.


## Whether the condition holds right now. [param character] is who it's asked about, such as the
## character changing jobs; it's null for POIs and other checks about the whole party.
@abstract func is_met(session: GameSession, character: Character = null) -> bool
