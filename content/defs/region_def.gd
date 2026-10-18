class_name RegionDef extends Def
## A named area of a map, such as Greenvale or the Frost Reach. Paint it on the editor-only region
## layer with tiles whose "region_id" custom data holds this id. Entering one shows its name.

## The random battles met here, or null for none.
@export var encounters: EncounterTable
