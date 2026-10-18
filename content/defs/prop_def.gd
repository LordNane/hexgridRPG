class_name PropDef extends Def
## Something standing on one hex of a battle arena, such as a tree or a rock. Paint it on the arena's
## prop layer with tiles whose "prop_id" custom data holds this id.

## Whether units can't enter its hex.
@export var blocks_movement := true
## Whether it stops arrows and spells aimed past it, from Phase 6.
@export var blocks_sight := true
