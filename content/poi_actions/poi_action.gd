@abstract
class_name PoiAction extends Resource
## One step of a POI's behavior. A POI runs its actions in order; each new behavior is one small
## subclass, combined with the others in the inspector.


## Performs the step. May await, for example until the player dismisses a message, so callers
## must await it.
@abstract func run(ctx: PoiContext) -> void
